import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/helper/app_helper.dart';
import 'package:tradexpro_flutter/helper/main_bg_view.dart';
import 'package:tradexpro_flutter/utils/alert_util.dart';
import 'package:tradexpro_flutter/utils/appbar_util.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';
import 'package:tradexpro_flutter/utils/number_util.dart';
import 'package:tradexpro_flutter/helper/app_widgets.dart';
import 'package:tradexpro_flutter/utils/button_util.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';
import 'package:tradexpro_flutter/utils/spacers.dart';
import 'package:tradexpro_flutter/utils/text_field_util.dart';

import 'sell_crypto_controller.dart';

class SellCryptoScreen extends StatefulWidget {
  const SellCryptoScreen({Key? key}) : super(key: key);

  @override
  State<SellCryptoScreen> createState() => _SellCryptoScreenState();
}

class _SellCryptoScreenState extends State<SellCryptoScreen> {
  final _controller = Get.put(SellCryptoController());
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      checkKYCVerifyStatus(context, onCancel: () => Get.back());
      _controller.getWalletListByType(CurrencyType.fiat);
      _controller.getWalletListByType(CurrencyType.crypto);
      _controller.fromEditController.text = 1.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BGViewMain(
        child: SafeArea(
            child: Padding(
                padding: const EdgeInsets.only(top: Dimens.paddingMainViewTop),
                child: Column(
                  children: [
                    appBarBackWithActions(title: "Sell Crypto".tr),
                    Expanded(child: Obx(() {
                      final fCoin = _controller.selectedFromWallet.value;
                      final tCoin = _controller.selectedToWallet.value;
                      return ListView(
                        padding: const EdgeInsets.all(Dimens.paddingMid),
                        children: [
                          vSpacer10(),
                          twoTextSpaceFixed("From".tr, "${"Available".tr} ${coinFormat(fCoin.balance)} ${fCoin.coinType ?? ""}"),
                          vSpacer5(),
                          textFieldWithWidget(
                              controller: _controller.fromEditController,
                              type: const TextInputType.numberWithOptions(decimal: true),
                              onTextChange: _onTextChanged,
                              suffixWidget: walletsSuffixView(_controller.cryptoList, fCoin, onChange: (selected) {
                                _controller.selectedFromWallet.value = selected;
                                _controller.getAndSetCoinRate();
                              })),
                          vSpacer20(),
                          twoTextSpaceFixed("To".tr, "${"Available".tr} ${coinFormat(tCoin.balance)} ${tCoin.coinType ?? ""}"),
                          vSpacer5(),
                          textFieldWithWidget(
                              controller: _controller.toEditController,
                              readOnly: true,
                              suffixWidget: walletsSuffixView(_controller.currencyList, tCoin, onChange: (selected) {
                                _controller.selectedToWallet.value = selected;
                                _controller.getAndSetCoinRate();
                              })),
                          _coinRateView(),
                          vSpacer20(),
                          buttonRoundedMain(text: "Sell".tr, onPressCallback: () => _checkInputData())
                        ],
                      );
                    }))
                  ],
                ))),
      ),
    );
  }

  Widget _coinRateView() {
    return Obx(() => Column(children: [
          vSpacer10(),
          twoTextSpace("Price".tr,
              "1 ${_controller.selectedFromWallet.value.coinType ?? ""} = ${_controller.rate.value} ${_controller.selectedToWallet.value.coinType ?? ""}"),
          twoTextSpace("You will spend".tr, "${_controller.convertRate.value} ${_controller.selectedToWallet.value.coinType ?? ""}",
              subColor: context.theme.colorScheme.secondary),
          vSpacer10(),
        ]));
  }

  void _onTextChanged(String amount) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 1), () {
      _controller.getAndSetCoinRate();
    });
  }

  void _checkInputData() {
    final amount = makeDouble(_controller.fromEditController.text.trim());
    if (amount <= 0) {
      showToast("Invalid amount".tr);
      return;
    }
    final buyAmount = makeDouble(_controller.toEditController.text.trim());
    final subTitle =
        "${"You will sell".tr} $amount ${_controller.selectedFromWallet.value.coinType ?? ""} ${"for".tr} $buyAmount ${_controller.selectedToWallet.value.coinType ?? ""}";
    alertForAction(context, title: "Sell Crypto".tr, subTitle: subTitle, buttonTitle: "Sell".tr, onOkAction: () {
      Get.back();
      _controller.swapCoinProcess(_controller.selectedFromWallet.value.id, _controller.selectedToWallet.value.id, amount);
    });
  }
}
