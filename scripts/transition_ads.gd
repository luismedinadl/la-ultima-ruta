extends Node

const LIVE_UNIT := "ca-app-pub-5544081559972494/7024745675"
const TEST_UNIT := "ca-app-pub-3940256099942544/1033173712"

var ad: InterstitialAd
var initialized := false
var initializing := false
var loading := false
var presenting := false
var loaded_at := 0
var continuation: Callable
var previously_muted := false
var diagnostic := "SDK • Android"
var updating_consent := false
var retry_delay := 10

func _ready() -> void:
	refresh_consent()

func refresh_consent() -> void:
	if updating_consent: return
	if OS.get_name() == "Android" and Engine.has_singleton("PoingGodotAdMobConsentInformation"):
		updating_consent = true
		diagnostic = "UMP…"
		UserMessagingPlatform.consent_information.update(ConsentRequestParameters.new(), _consent_updated, _consent_failed)

func _consent_failed(error: FormError) -> void:
	updating_consent = false
	diagnostic = "UMP %d · %s" % [error.error_code, error.message]
	push_warning(diagnostic)
	if permitted(): prepare()

func _consent_updated() -> void:
	if permitted():
		updating_consent = false
		prepare()
	elif UserMessagingPlatform.consent_information.get_is_consent_form_available():
		UserMessagingPlatform.load_consent_form(func(form: ConsentForm): form.show(_privacy_changed), _consent_failed)
	else:
		updating_consent = false
		diagnostic = "UMP · %d" % UserMessagingPlatform.consent_information.get_consent_status()

func privacy_required() -> bool:
	return OS.get_name() == "Android" and UserMessagingPlatform.consent_information.get_privacy_options_requirement_status() == ConsentInformation.PrivacyOptionsRequirementStatus.REQUIRED

func privacy_options() -> void:
	UserMessagingPlatform.show_privacy_options_form(_privacy_changed)

func _privacy_changed(_error: FormError) -> void:
	updating_consent = false
	if _error:
		_consent_failed(_error)
		return
	if ad:
		ad.destroy()
		ad = null
	prepare()

func permitted() -> bool:
	return OS.get_name() == "Android" and UserMessagingPlatform.consent_information.get_consent_status() in [ConsentInformation.ConsentStatus.NOT_REQUIRED, ConsentInformation.ConsentStatus.OBTAINED]

func prepare() -> void:
	if not permitted() or loading or initializing or ad: return
	if not initialized:
		diagnostic = "Mobile Ads SDK…"
		initializing = true
		var listener := OnInitializationCompleteListener.new()
		listener.on_initialization_complete = func(_status: InitializationStatus):
			initializing = false
			initialized = true
			prepare()
		MobileAds.initialize(listener)
		return
	loading = true
	diagnostic = "AdMob…"
	var callback := InterstitialAdLoadCallback.new()
	callback.on_ad_failed_to_load = func(error: LoadAdError):
		loading = false
		diagnostic = "AdMob %d · %s" % [error.code, error.message] if error else "AdMob · ?"
		push_warning(diagnostic)
		get_tree().create_timer(retry_delay).timeout.connect(prepare, CONNECT_ONE_SHOT)
		retry_delay = mini(retry_delay * 2, 120)
	callback.on_ad_loaded = func(loaded: InterstitialAd):
		loading = false
		if not permitted():
			loaded.destroy()
			return
		ad = loaded
		retry_delay = 10
		diagnostic = "OK"
		loaded_at = Time.get_ticks_msec()
	InterstitialAdLoader.new().load(TEST_UNIT if OS.is_debug_build() else LIVE_UNIT, AdRequest.new(), callback)

func transition(next: Callable) -> void:
	if presenting: return
	if ad and Time.get_ticks_msec() - loaded_at >= 3600000:
		ad.destroy()
		ad = null
	if not ad or not permitted():
		next.call()
		prepare()
		return
	continuation = next
	presenting = true
	previously_muted = AudioServer.is_bus_mute(0)
	AudioServer.set_bus_mute(0, true)
	var callback := FullScreenContentCallback.new()
	callback.on_ad_dismissed_full_screen_content = _finish
	callback.on_ad_failed_to_show_full_screen_content = func(_error: AdError): _finish()
	ad.full_screen_content_callback = callback
	ad.show()

func _finish() -> void:
	if not presenting: return
	presenting = false
	AudioServer.set_bus_mute(0, previously_muted)
	ad.destroy()
	ad = null
	var next := continuation
	continuation = Callable()
	next.call()
	prepare()
