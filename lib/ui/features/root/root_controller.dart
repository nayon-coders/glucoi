import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:tradexpro_flutter/data/local/api_constants.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/data/models/kyc_details.dart';
import 'package:tradexpro_flutter/data/remote/socket_provider.dart';
import 'package:tradexpro_flutter/data/models/socket_response.dart';
import 'package:tradexpro_flutter/data/models/user.dart';
import 'package:tradexpro_flutter/data/remote/api_repository.dart';
import 'package:tradexpro_flutter/helper/app_helper.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';
import 'package:tradexpro_flutter/utils/firebase_messaging_util.dart';

class RootController extends GetxController implements SocketListener {
  RxInt notificationCount = 0.obs;
  int bottomNavIndex = DefaultValue.showLanding ? 13 : 0;
  late Function(int, bool, {int? subIndex}) changeBottomNavIndex;
  int selectedTradeIndex = 0;

  @override
  void onDataGet(channel, event, data) {
    if (event == SocketConstants.eventNotification) {
      notificationCount.value++;
      if (data is NotificationData) showToast(data.notifyMessage(), isError: false);
    }
  }

  void setMyProfile() {
    var userMap = GetStorage().read(PreferenceKey.userObject);
    if (userMap != null) {
      try {
        gUserRx.value = User.fromJson(userMap);
      } catch (error) {
        printFunction("setMyProfile error", error);
      }
    }
    gIsKYCVerified =  GetStorage().read(PreferenceKey.isKycVerified);
    Future.delayed(const Duration(seconds: 3), () => getMyProfile());
  }

  void getMyProfile() async {
    if (gUserRx.value.id == 0) return;
    APIRepository().getSelfProfile().then((resp) {
      if (resp.success) {
        var userMap = resp.data[APIKeyConstants.user];
        if (userMap != null) {
          GetStorage().write(PreferenceKey.userObject, userMap);
          gUserRx.value = User.fromJson(userMap);
          getNotificationCount();
          getKYCSettingsDetails();
        }
      }
      if (gUserRx.value.id != 0) {
        String channelNotify = SocketConstants.channelNotification + gUserRx.value.id.toString();
        APIRepository().subscribeEvent(channelNotify, this);
        _updateFCMToken();
      }
    });
  }

  Future<void> _updateFCMToken() async {
    if (gUserRx.value.id > 0) {
      final currentToken = await FirebaseMessagingUtil.on().getFCMToken();
      final savedToken = GetStorage().read(PreferenceKey.firebaseToken);
      if (currentToken != null && currentToken != savedToken) {
        final deviceInfo = await getDeviceIdentifier();
        APIRepository().updateDeviceToken(deviceInfo.last, currentToken, deviceInfo.first).then((resp) {
          if (resp.success) {
            GetStorage().write(PreferenceKey.firebaseToken, currentToken);
          }
        });
      }
    }
  }

  void getCommonSettings() async {
    APIRepository().getCommonSettings().then((resp) {
      if (resp.success && resp.data != null && resp.data is Map<String, dynamic>) {
        final settings = resp.data[APIKeyConstants.commonSettings];
        if (settings != null && settings is Map<String, dynamic>) {
          GetStorage().write(PreferenceKey.settingsObject, settings);
        }
      }
    });
  }

  void getKYCSettingsDetails() {
    APIRepository().getUserKYCSettingsDetails().then((resp) {
      if (resp.success) {
        setKYCVerified(KycSettings.fromJson(resp.data));
      } else {
        showToast(resp.message);
      }
    }, onError: (err) => showToast(err.toString()));
  }

  void logOut() {
    showLoadingDialog();
    APIRepository().logoutUser().then((resp) {
      hideLoadingDialog();
      showToast(resp.message, isError: !resp.success);
      if (resp.success) logOutActions();
    }, onError: (err) {
      hideLoadingDialog();
      err.toString() == ErrorConstants.unauthorized ? logOutActions() : showToast(err.toString());
    });
  }

  void getNotificationCount() {
    APIRepository().getNotifications().then((resp) {
      if (resp.success) {
        notificationCount.value = (resp.data as List? ?? []).length;
      }
    }, onError: (err) {});
  }
}
