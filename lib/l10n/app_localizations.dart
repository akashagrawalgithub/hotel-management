import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'appTitle': 'Flash Room',
      'profile': 'Profile',
      'setting': 'Setting',
      'yourCard': 'Your Card',
      'securityPrivacy': 'Security & Privacy',
      'aboutUs': 'About Us',
      'notification': 'Notification',
      'languages': 'Languages',
      'helpSupport': 'Help and Support',
      'contactUs': 'Contact Us',
      'logout': 'Logout',
      'areYouSure': 'Are You Sure?',
      'doYouWantToLogOut': 'Do you want to log out ?',
      'logOut': 'Log Out',
      'cancel': 'Cancel',
      'welcomeTo': 'Welcome to',
      'flashRooms': 'Flash Rooms',
      'bestPlaceDescription': 'The best place to find millions of of apartment near by temples',
      'enterYourEmail': 'Enter your email',
      'enterYourPassword': 'Enter your password',
      'forgotPassword': 'Forgot Password?',
      'login': 'Login',
      'orLoginWith': 'Or Login with',
      'skipForNow': 'Skip For Now',
      'dontHaveAccount': "Don't have an account?",
      'registerNow': 'Register Now',
      'alreadyHaveAccount': 'Already have an account?',
      'loginNow': 'Login Now',
      'alreadyHaveAccount': 'Already have an account?',
      'loginNow': 'Login Now',
      'hey': 'Hey',
      'letsStartJourney': "Let's start your journey!",
      'location': 'Location',
      'enterYourDestination': 'Enter your destination',
      'date': 'Date',
      'selectDate': 'Select Date',
      'guest': 'Guest',
      'addGuest': 'Add guest',
      'search': 'Search',
      'all': 'All',
      'acRoom': 'AC Room',
      'fourStars': '4 Stars',
      'nearMe': 'Near Me',
      'mans': 'Mans',
      'luxury': 'Luxury',
      'budget': 'Budget',
      'hotelNearYou': 'Hotel Near You',
      'noHotelsAvailable': 'No hotels available',
      'night': '/night',
      'pleaseEnterYourEmail': 'Please enter your email',
      'pleaseEnterValidEmail': 'Please enter a valid email',
      'pleaseEnterYourPassword': 'Please enter your password',
      'pleaseEnterYourName': 'Please enter your name',
      'pleaseConfirmYourPassword': 'Please confirm your password',
      'passwordsDoNotMatch': 'Passwords do not match',
      'passwordMinChars': 'Password must be at least 6 characters',
      'pleaseEnterYourName': 'Please enter your name',
      'pleaseConfirmYourPassword': 'Please confirm your password',
      'passwordsDoNotMatch': 'Passwords do not match',
      'passwordMinChars': 'Password must be at least 6 characters',
      'selectLanguage': 'Select Language',
      'english': 'English',
      'hindi': 'हिंदी',
      'booking': 'Booking',
      'reviews': 'reviews',
      'checkIn': 'Check - In',
      'checkOut': 'Check - Out',
      'numberOfGuests': 'Number of Guests',
      'payWith': 'Pay With',
      'edit': 'Edit',
      'paymentDetails': 'Payment Details',
      'total': 'Total',
      'nightWord': 'Night',
      'cleaningFee': 'Cleaning Fee',
      'serviceFee': 'Service Fee',
      'discount': 'Discount',
      'totalPayment': 'Total Payment:',
      'guestInformation': 'Guest Information',
      'fullName': 'Full Name',
      'name': 'Name',
      'name': 'Name',
      'email': 'Email',
      'phoneNumber': 'Phone Number',
      'totalPrice': 'Total price',
      'searchResults': 'Search Results',
      'resultsFound': 'result',
      'resultsFoundPlural': 'results',
      'found': 'found',
      'noData': "We don't have any data",
      'tryAdjustingSearch': 'Try adjusting your search criteria',
      'myBookings': 'My Bookings',
      'findYourSpace': 'Find your space',
      'booked': 'Booked',
      'history': 'History',
      'noBookingsFound': 'No bookings found',
      'noBookingHistoryFound': 'No booking history found',
      'dates': 'Dates',
      'datesNotAvailable': 'Dates not available',
      'locationNotAvailable': 'Location not available',
      'guests': 'Guests',
      'room': 'Room',
      'rooms': 'Rooms',
      'bestMatchForYou': 'Best match for you',
      'recommendedForYou': 'Recommended for You',
      'today': 'Today',
      'yesterday': 'Yesterday',
      'hoursAgo': '2 hours Ago',
      'hotelAddedRooms': 'Hotel Eliminate Galian has added new accommodation rooms',
      'discountNotification': '20% discount if you stay on Saturday 27 November 2024 at Cerulean Hotel',
      'bookingSuccessNotification': 'Congratulations, you have successfully booked a room at Jade Gem Resort',
      'paymentSuccessNotification': 'Payment has been successfully made, order is being processed',
      'freeBreakfastNotification': 'Free breakfast at Double Oak Hotel for November 27, 2024',
      'noNotifications': 'No notifications',
      'noNotificationsMessage': 'You\'re all caught up!',
      'resetPasswordDescription': 'Enter your email address and we will send you a reset link',
      'sendResetLink': 'Send Reset Link',
      'resetLinkSent': 'Reset Link Sent',
      'resetLinkSentMessage': 'We have sent a password reset link to your email address. Please check your inbox.',
      'backToLogin': 'Back to Login',
      'ok': 'OK',
    },
    'hi': {
      'appTitle': 'फ्लैश रूम',
      'profile': 'प्रोफ़ाइल',
      'setting': 'सेटिंग',
      'yourCard': 'आपका कार्ड',
      'securityPrivacy': 'सुरक्षा और गोपनीयता',
      'aboutUs': 'हमारे बारे में',
      'notification': 'सूचना',
      'languages': 'भाषाएं',
      'helpSupport': 'सहायता और समर्थन',
      'contactUs': 'संपर्क करें',
      'logout': 'लॉग आउट',
      'areYouSure': 'क्या आप सुनिश्चित हैं?',
      'doYouWantToLogOut': 'क्या आप लॉग आउट करना चाहते हैं?',
      'logOut': 'लॉग आउट',
      'cancel': 'रद्द करें',
      'welcomeTo': 'स्वागत है',
      'flashRooms': 'फ्लैश रूम्स',
      'bestPlaceDescription': 'मंदिरों के पास लाखों अपार्टमेंट खोजने के लिए सबसे अच्छी जगह',
      'enterYourEmail': 'अपना ईमेल दर्ज करें',
      'enterYourPassword': 'अपना पासवर्ड दर्ज करें',
      'forgotPassword': 'पासवर्ड भूल गए?',
      'login': 'लॉग इन',
      'orLoginWith': 'या इसके साथ लॉग इन करें',
      'skipForNow': 'अभी के लिए छोड़ें',
      'dontHaveAccount': 'खाता नहीं है?',
      'registerNow': 'अभी पंजीकरण करें',
      'hey': 'नमस्ते',
      'letsStartJourney': 'अपनी यात्रा शुरू करें!',
      'location': 'स्थान',
      'enterYourDestination': 'अपना गंतव्य दर्ज करें',
      'date': 'तारीख',
      'selectDate': 'तारीख चुनें',
      'guest': 'अतिथि',
      'addGuest': 'अतिथि जोड़ें',
      'search': 'खोजें',
      'all': 'सभी',
      'acRoom': 'एसी कमरा',
      'fourStars': '4 सितारे',
      'nearMe': 'मेरे पास',
      'mans': 'मैन्स',
      'luxury': 'लक्जरी',
      'budget': 'बजट',
      'hotelNearYou': 'आपके पास होटल',
      'noHotelsAvailable': 'कोई होटल उपलब्ध नहीं',
      'night': '/रात',
      'pleaseEnterYourEmail': 'कृपया अपना ईमेल दर्ज करें',
      'pleaseEnterValidEmail': 'कृपया एक वैध ईमेल दर्ज करें',
      'pleaseEnterYourPassword': 'कृपया अपना पासवर्ड दर्ज करें',
      'pleaseEnterYourName': 'कृपया अपना नाम दर्ज करें',
      'pleaseConfirmYourPassword': 'कृपया अपना पासवर्ड पुष्टि करें',
      'passwordsDoNotMatch': 'पासवर्ड मेल नहीं खाते',
      'passwordMinChars': 'पासवर्ड कम से कम 6 अक्षरों का होना चाहिए',
      'selectLanguage': 'भाषा चुनें',
      'english': 'English',
      'hindi': 'हिंदी',
      'booking': 'बुकिंग',
      'reviews': 'समीक्षाएं',
      'checkIn': 'चेक - इन',
      'checkOut': 'चेक - आउट',
      'numberOfGuests': 'अतिथियों की संख्या',
      'payWith': 'के साथ भुगतान करें',
      'edit': 'संपादित करें',
      'paymentDetails': 'भुगतान विवरण',
      'total': 'कुल',
      'nightWord': 'रात',
      'cleaningFee': 'सफाई शुल्क',
      'serviceFee': 'सेवा शुल्क',
      'discount': 'छूट',
      'totalPayment': 'कुल भुगतान:',
      'guestInformation': 'अतिथि जानकारी',
      'fullName': 'पूरा नाम',
      'name': 'नाम',
      'email': 'ईमेल',
      'phoneNumber': 'फोन नंबर',
      'totalPrice': 'कुल मूल्य',
      'searchResults': 'खोज परिणाम',
      'resultsFound': 'परिणाम',
      'resultsFoundPlural': 'परिणाम',
      'found': 'मिला',
      'noData': 'हमारे पास कोई डेटा नहीं है',
      'tryAdjustingSearch': 'अपने खोज मानदंडों को समायोजित करने का प्रयास करें',
      'myBookings': 'मेरी बुकिंग',
      'findYourSpace': 'अपनी जगह खोजें',
      'booked': 'बुक किया गया',
      'history': 'इतिहास',
      'noBookingsFound': 'कोई बुकिंग नहीं मिली',
      'noBookingHistoryFound': 'कोई बुकिंग इतिहास नहीं मिला',
      'dates': 'तारीखें',
      'datesNotAvailable': 'तारीखें उपलब्ध नहीं',
      'locationNotAvailable': 'स्थान उपलब्ध नहीं',
      'guests': 'अतिथि',
      'room': 'कमरा',
      'rooms': 'कमरे',
      'bestMatchForYou': 'आपके लिए सबसे अच्छा मैच',
      'recommendedForYou': 'आपके लिए अनुशंसित',
      'today': 'आज',
      'yesterday': 'कल',
      'hoursAgo': '2 घंटे पहले',
      'hotelAddedRooms': 'होटल एलिमिनेट गैलियन ने नए आवास कमरे जोड़े हैं',
      'discountNotification': '27 नवंबर 2024 को सेरुलियन होटल में रहने पर 20% छूट',
      'bookingSuccessNotification': 'बधाई हो, आपने जेड जेम रिसॉर्ट में कमरा सफलतापूर्वक बुक किया है',
      'paymentSuccessNotification': 'भुगतान सफलतापूर्वक किया गया है, ऑर्डर प्रसंस्करण में है',
      'freeBreakfastNotification': '27 नवंबर, 2024 को डबल ओक होटल में निःशुल्क नाश्ता',
      'noNotifications': 'कोई सूचनाएं नहीं',
      'noNotificationsMessage': 'आप सभी अपडेट हैं!',
      'resetPasswordDescription': 'अपना ईमेल पता दर्ज करें और हम आपको एक रीसेट लिंक भेजेंगे',
      'sendResetLink': 'रीसेट लिंक भेजें',
      'resetLinkSent': 'रीसेट लिंक भेज दिया गया',
      'resetLinkSentMessage': 'हमने आपके ईमेल पते पर एक पासवर्ड रीसेट लिंक भेजा है। कृपया अपना इनबॉक्स जांचें।',
      'backToLogin': 'लॉगिन पर वापस जाएं',
      'ok': 'ठीक है',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }

  String get appTitle => translate('appTitle');
  String get profile => translate('profile');
  String get setting => translate('setting');
  String get yourCard => translate('yourCard');
  String get securityPrivacy => translate('securityPrivacy');
  String get aboutUs => translate('aboutUs');
  String get notification => translate('notification');
  String get languages => translate('languages');
  String get helpSupport => translate('helpSupport');
  String get contactUs => translate('contactUs');
  String get logout => translate('logout');
  String get areYouSure => translate('areYouSure');
  String get doYouWantToLogOut => translate('doYouWantToLogOut');
  String get logOut => translate('logOut');
  String get cancel => translate('cancel');
  String get welcomeTo => translate('welcomeTo');
  String get flashRooms => translate('flashRooms');
  String get bestPlaceDescription => translate('bestPlaceDescription');
  String get enterYourEmail => translate('enterYourEmail');
  String get enterYourPassword => translate('enterYourPassword');
  String get forgotPassword => translate('forgotPassword');
  String get login => translate('login');
  String get orLoginWith => translate('orLoginWith');
  String get skipForNow => translate('skipForNow');
  String get dontHaveAccount => translate('dontHaveAccount');
  String get registerNow => translate('registerNow');
  String get hey => translate('hey');
  String get letsStartJourney => translate('letsStartJourney');
  String get location => translate('location');
  String get enterYourDestination => translate('enterYourDestination');
  String get date => translate('date');
  String get selectDate => translate('selectDate');
  String get guest => translate('guest');
  String get addGuest => translate('addGuest');
  String get search => translate('search');
  String get all => translate('all');
  String get acRoom => translate('acRoom');
  String get fourStars => translate('fourStars');
  String get nearMe => translate('nearMe');
  String get mans => translate('mans');
  String get luxury => translate('luxury');
  String get budget => translate('budget');
  String get hotelNearYou => translate('hotelNearYou');
  String get noHotelsAvailable => translate('noHotelsAvailable');
  String get night => translate('night');
  String get pleaseEnterYourEmail => translate('pleaseEnterYourEmail');
  String get pleaseEnterValidEmail => translate('pleaseEnterValidEmail');
  String get pleaseEnterYourPassword => translate('pleaseEnterYourPassword');
  String get pleaseEnterYourName => translate('pleaseEnterYourName');
  String get pleaseConfirmYourPassword => translate('pleaseConfirmYourPassword');
  String get passwordsDoNotMatch => translate('passwordsDoNotMatch');
  String get passwordMinChars => translate('passwordMinChars');
  String get selectLanguage => translate('selectLanguage');
  String get english => translate('english');
  String get hindi => translate('hindi');
  String get booking => translate('booking');
  String get reviews => translate('reviews');
  String get checkIn => translate('checkIn');
  String get checkOut => translate('checkOut');
  String get numberOfGuests => translate('numberOfGuests');
  String get payWith => translate('payWith');
  String get edit => translate('edit');
  String get paymentDetails => translate('paymentDetails');
  String get total => translate('total');
  String get nightWord => translate('nightWord');
  String get cleaningFee => translate('cleaningFee');
  String get serviceFee => translate('serviceFee');
  String get discount => translate('discount');
  String get totalPayment => translate('totalPayment');
  String get guestInformation => translate('guestInformation');
  String get fullName => translate('fullName');
  String get name => translate('name');
  String get email => translate('email');
  String get phoneNumber => translate('phoneNumber');
  String get totalPrice => translate('totalPrice');
  String get searchResults => translate('searchResults');
  String get resultsFound => translate('resultsFound');
  String get resultsFoundPlural => translate('resultsFoundPlural');
  String get found => translate('found');
  String get noData => translate('noData');
  String get tryAdjustingSearch => translate('tryAdjustingSearch');
  String get myBookings => translate('myBookings');
  String get findYourSpace => translate('findYourSpace');
  String get booked => translate('booked');
  String get history => translate('history');
  String get alreadyHaveAccount => translate('alreadyHaveAccount');
  String get loginNow => translate('loginNow');
  String get noBookingsFound => translate('noBookingsFound');
  String get noBookingHistoryFound => translate('noBookingHistoryFound');
  String get dates => translate('dates');
  String get datesNotAvailable => translate('datesNotAvailable');
  String get locationNotAvailable => translate('locationNotAvailable');
  String get guests => translate('guests');
  String get room => translate('room');
  String get rooms => translate('rooms');
  String get bestMatchForYou => translate('bestMatchForYou');
  String get recommendedForYou => translate('recommendedForYou');
  String get today => translate('today');
  String get yesterday => translate('yesterday');
  String get hoursAgo => translate('hoursAgo');
  String get hotelAddedRooms => translate('hotelAddedRooms');
  String get discountNotification => translate('discountNotification');
  String get bookingSuccessNotification => translate('bookingSuccessNotification');
  String get paymentSuccessNotification => translate('paymentSuccessNotification');
  String get freeBreakfastNotification => translate('freeBreakfastNotification');
  String get noNotifications => translate('noNotifications');
  String get noNotificationsMessage => translate('noNotificationsMessage');
  String get resetPasswordDescription => translate('resetPasswordDescription');
  String get sendResetLink => translate('sendResetLink');
  String get resetLinkSent => translate('resetLinkSent');
  String get resetLinkSentMessage => translate('resetLinkSentMessage');
  String get backToLogin => translate('backToLogin');
  String get ok => translate('ok');
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'hi'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

