import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/data/models/kyc_details.dart';
import 'package:tradexpro_flutter/utils/alert_util.dart';
import 'package:tradexpro_flutter/utils/button_util.dart';
import 'package:tradexpro_flutter/utils/common_widgets.dart';
import 'package:tradexpro_flutter/utils/decorations.dart';
import 'package:tradexpro_flutter/utils/image_util.dart';
import 'package:tradexpro_flutter/utils/number_util.dart';
import 'package:tradexpro_flutter/utils/text_util.dart';
import 'package:tradexpro_flutter/helper/app_helper.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';
import 'package:tradexpro_flutter/utils/spacers.dart';
import 'kyc_controller.dart';
import 'kyc_dojah_screen.dart';

class KYCScreen extends StatefulWidget {
  const KYCScreen({Key? key}) : super(key: key);

  @override
  State<KYCScreen> createState() => _KYCScreenState();
}

class _KYCScreenState extends State<KYCScreen> {
  final _controller = Get.put(KycController());
  Rx<File> frontImage = File("").obs;
  Rx<File> backImage = File("").obs;
  Rx<File> selfieImage = File("").obs;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) => _controller.getKYCSettingsDetails());
  }

  @override
  void dispose() {
    _clearView();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        final settings = getSettingsLocal();
        final enabledType = _controller.kycSettingsRx.value.enabledKycType;
        return Expanded(
          child: _controller.isDataLoading.value
              ? showLoading()
              : ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(Dimens.paddingMid),
                  children: [
                    if (settings?.dailyMaxWithdrawDepositStatus == 1)
                      Column(
                        children: [
                          TierLimitItemView(
                              isActive: gUserRx.value.isVerified == 1,
                              amount: 0,
                              require: "Registered_account_with".trParams({"name": _controller.appName}),
                              tier: 1),
                          vSpacer10(),
                          TierLimitItemView(
                              isActive: gIsKYCVerified,
                              amount: settings?.dailyMaxWithdrawDepositAmount ?? 0,
                              require: "KYC Verification".tr,
                              tier: 2),
                        ],
                      ),
                    if (enabledType == KYCType.manual)
                      _manualVerificationView(_controller.kycDetailsRx.value)
                    else if (enabledType == KYCType.persona)
                      _controller.kycSettingsRx.value.enabledKycUserDetails?.persona?.isVerified == 1
                          ? _kycVerifySuccessView()
                          : _kycVerifyNeedView(enabledType)
                    else if (enabledType == KYCType.dojah)
                      _controller.kycSettingsRx.value.enabledKycUserDetails?.dojah?.isVerified == 1
                          ? _kycVerifySuccessView()
                          : _kycVerifyNeedView(enabledType)
                    // _kycVerifyNeedView(enabledType)
                    else
                      Column(children: [
                        vSpacer30(),
                        Icon(Icons.person_add_disabled, color: context.theme.focusColor, size: Dimens.iconSizeLargeExtra),
                        vSpacer10(),
                        textAutoSizeTitle("Kyc disabled".tr),
                      ])
                  ],
                ),
        );
      },
    );
  }

  _kycVerifySuccessView() {
    return Column(children: [
      vSpacer30(),
      const Icon(Icons.how_to_reg, color: Colors.green, size: Dimens.iconSizeLogo),
      vSpacer10(),
      textAutoSizeTitle("Verified Successfully".tr, color: Colors.green),
    ]);
  }

  _kycVerifyNeedView(int enabledKycType) {
    return Column(children: [
      vSpacer30(),
      Icon(Icons.photo_camera_outlined, color: context.theme.primaryColor, size: Dimens.iconSizeLargeExtra),
      vSpacer10(),
      textAutoSizeTitle("Verify your identity".tr),
      vSpacer20(),
      buttonRoundedMain(text: "Start".tr, width: context.width / 2, onPressCallback: () => _startKycVerification(enabledKycType))
    ]);
  }

  // _kycVerifyNeedView(int enabledKycType) {
  //   return Column(children: [
  //     vSpacer30(),
  //     Icon(Icons.photo_camera_outlined, color: context.theme.primaryColor, size: Dimens.iconSizeLargeExtra),
  //     vSpacer10(),
  //     textAutoSizeTitle("Verify your identity".tr),
  //     vSpacer10(),
  //     textSpanWithAction(
  //         "If asked for your email, please input your login email".tr, gUserRx.value.email ?? '', () => copyToClipboard(gUserRx.value.email ?? ''),
  //         maxLines: 3),
  //     vSpacer20(),
  //     buttonRoundedMain(text: "Start".tr, width: context.width / 2, onPressCallback: () => _startKycVerification(enabledKycType))
  //   ]);
  // }

  void _startKycVerification(int enabledKycType) async {
    if (enabledKycType == KYCType.persona) {
      // PersonaUtil().start(Theme.of(context), gUserRx.value, kycSettingsRx.value.personaCredentialsDetails, (success, inquiryId) {
      //   if (success) {
      //     _controller.verifyThirdPartyKyc(inquiryId, (onSuccess) {
      //       _controller.getKYCSettingsDetails((settings) => kycSettingsRx.value = settings);
      //     });
      //   }
      // });
    } else if (enabledKycType == KYCType.dojah) {
      Get.to(() => const KYCDojahScreen());

      // if (kycSettingsRx.value.dojahVerificationLink.isValid) {
      //   final result = await Get.to(() => WebViewPage(url: kycSettingsRx.value.dojahVerificationLink ?? '', fromKey: KYCType.dojah.toString()));
      //   if (result != null && result == true) _controller.getKYCSettingsDetails((settings) => kycSettingsRx.value = settings);
      // } else {
      //   showToast("Verification link not found".tr);
      // }
    }
  }

  _manualVerificationView(KycDetails details) {
    return Column(children: [
      Align(alignment: Alignment.centerLeft, child: textAutoSizePoppins("KYC Verification List".tr, fontSize: Dimens.regularFontSizeExtraMid)),
      if (details.nid != null) _kycItemView(details.nid, "National ID Card".tr, AssetConstants.imgNID),
      if (details.nid != null) vSpacer20(),
      if (details.passport != null) _kycItemView(details.passport, "Passport".tr, AssetConstants.imgPassport),
      if (details.passport != null) vSpacer20(),
      if (details.driving != null) _kycItemView(details.driving, "Driving License".tr, AssetConstants.imgDrivingLicense),
      if (details.driving != null) vSpacer20(),
      if (details.voter != null) _kycItemView(details.voter, "Voter Card".tr, AssetConstants.imgVoterCard),
      if (details.voter != null) vSpacer20(),
    ]);
  }

  _kycItemView(KycObject? kyc, String title, String imagePath) {
    final sData = getIdVerificationStatusData(kyc?.status);
    return Column(
      children: [
        InkWell(
          onTap: () => showBottomSheetFullScreen(context, _showUploadView(kyc), title: title, onClose: () => _clearView()),
          child: Container(
            decoration: boxDecorationRoundCorner(radius: Dimens.radiusCornerMid),
            margin: const EdgeInsets.all(Dimens.paddingLarge),
            height: context.width / 2,
            width: context.width,
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: Stack(
                    children: [
                      showImageAsset(
                          imagePath: AssetConstants.icRibbon,
                          height: Dimens.iconSizeMid,
                          width: context.width / 2.5,
                          boxFit: BoxFit.fitWidth,
                          color: sData.last),
                      Container(
                          padding: const EdgeInsets.all(Dimens.paddingMin),
                          height: Dimens.iconSizeMid,
                          width: context.width / 2.5,
                          child: sData.first,
                          color: Colors.white)
                    ],
                  ),
                ),
                Align(alignment: Alignment.center, child: showImageAsset(imagePath: imagePath, height: context.width / 4)),
              ],
            ),
          ),
        ),
        textAutoSizePoppins(title, fontSize: Dimens.regularFontSizeExtraMid)
      ],
    );
  }

  _showUploadView(KycObject? kyc) {
    return Expanded(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(Dimens.paddingMid),
        children: [
          vSpacer10(),
          textAutoSizeKarla("Front side".tr, textAlign: TextAlign.start, fontSize: Dimens.regularFontSizeMid),
          Obx(() => _showUploadImage(frontImage.value, PhotoType.front, kyc?.frontImage)),
          vSpacer20(),
          textAutoSizeKarla("Back side".tr, textAlign: TextAlign.start, fontSize: Dimens.regularFontSizeMid),
          Obx(() => _showUploadImage(backImage.value, PhotoType.back, kyc?.backImage)),
          vSpacer20(),
          textAutoSizeKarla("Selfie".tr, textAlign: TextAlign.start, fontSize: Dimens.regularFontSizeMid),
          Obx(() => _showUploadImage(selfieImage.value, PhotoType.selfie, kyc?.selfieImage)),
          vSpacer20(),
          if (kyc?.status == IdVerificationStatus.notSubmitted || kyc?.status == IdVerificationStatus.rejected)
            buttonRoundedMain(text: "Upload".tr, onPressCallback: () => _checkInputData(kyc)),
          vSpacer10(),
        ],
      ),
    );
  }

  Widget _showUploadImage(File file, PhotoType photoType, String? prePath) {
    prePath = prePath ?? "";
    return InkWell(
      child: Container(
        height: context.width / 2,
        width: context.width,
        margin: const EdgeInsets.all(Dimens.paddingLarge),
        decoration: boxDecorationRoundCorner(color: context.theme.colorScheme.background),
        child: file.path.isNotEmpty
            ? showImageLocal(file)
            : prePath.isNotEmpty
                ? showImageNetwork(imagePath: prePath)
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      buttonOnlyIcon(iconPath: AssetConstants.icUpload, size: Dimens.iconSizeMid),
                      vSpacer10(),
                      textAutoSizePoppins("Tap to upload photo".tr),
                    ],
                  ),
      ),
      onTap: () {
        showImageChooser(context, (chooseFile, isGallery) {
          isGallery
              ? _setImageInFile(photoType, chooseFile)
              : saveFileOnTempPath(chooseFile, onNewFile: (newFile) => _setImageInFile(photoType, newFile));
        }, isCrop: photoType == PhotoType.selfie, isGallery: photoType != PhotoType.selfie);
      },
    );
  }

  void _setImageInFile(PhotoType photoType, File file) {
    switch (photoType) {
      case PhotoType.front:
        frontImage.value = file;
        break;
      case PhotoType.back:
        backImage.value = file;
        break;
      case PhotoType.selfie:
        selfieImage.value = file;
        break;
    }
  }

  void _clearView() {
    frontImage.value = File("");
    backImage.value = File("");
    selfieImage.value = File("");
  }

  void _checkInputData(KycObject? kycObj) {
    if (frontImage.value.path.isEmpty) {
      showToast("Front image can not be empty".tr, isError: true);
      return;
    }
    if (backImage.value.path.isEmpty) {
      showToast("Back image can not be empty".tr, isError: true);
      return;
    }
    if (selfieImage.value.path.isEmpty) {
      showToast("Selfie image can not be empty".tr, isError: true);
      return;
    }
    IdVerificationType type = IdVerificationType.none;
    if (identical(kycObj, _controller.kycDetailsRx.value.nid)) {
      type = IdVerificationType.nid;
    } else if (identical(kycObj, _controller.kycDetailsRx.value.passport)) {
      type = IdVerificationType.passport;
    } else if (identical(kycObj, _controller.kycDetailsRx.value.driving)) {
      type = IdVerificationType.driving;
    } else if (identical(kycObj, _controller.kycDetailsRx.value.voter)) {
      type = IdVerificationType.voter;
    }
    _controller.uploadDocuments(type, frontImage.value, backImage.value, selfieImage.value, (kyc) => _controller.kycDetailsRx.value = kyc);
  }
}

class TierLimitItemView extends StatelessWidget {
  const TierLimitItemView({super.key, required this.isActive, required this.amount, required this.require, required this.tier});

  final bool isActive;
  final double amount;
  final String require;
  final int tier;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? context.theme.focusColor : Colors.grey;
    return Card(
      elevation: gIsDarkMode ? 10 : 0,
      color: Colors.transparent,
      shape: RoundedRectangleBorder(side: BorderSide(color: color), borderRadius: const BorderRadius.all(Radius.circular(Dimens.radiusCornerMid))),
      child: Padding(
        padding: const EdgeInsets.all(Dimens.paddingMid),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
                height: Dimens.btnHeightMin,
                child: buttonText("Tier".tr + tier.toString(), textColor: context.theme.scaffoldBackgroundColor, bgColor: color)),
            vSpacer10(),
            textAutoSizePoppins("24h Withdrawal Limit".tr),
            textAutoSizeKarla("NGN ${currencyFormat(amount)}"),
            vSpacer20(),
            textAutoSizePoppins("Requirement for this limit".tr),
            vSpacer5(),
            Row(
              children: [
                Icon(Icons.check_circle_rounded, size: Dimens.iconSizeMinExtra, color: color),
                hSpacer2(),
                textAutoSizePoppins(require),
              ],
            )
          ],
        ),
      ),
    );
  }
}
