import 'dart:async';
import 'dart:io';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:common_utils/common_utils.dart';
import 'package:flare_flutter/flare_actor.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_qr_reader/qrcode_reader_view.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QRView extends StatefulWidget {
  const QRView({
    @required Key key,
    @required this.data,
    this.overlay,
    this.qrCodeBackgroundColor = Colors.red,
    this.qrCodeForegroundColor = Colors.white,
    this.switchButtonColor = Colors.white,
  })  : assert(key != null),
        assert(data != null),
        super(key: key);

  final ShapeBorder overlay;
  final String data;
  final Color qrCodeBackgroundColor;
  final Color qrCodeForegroundColor;
  final Color switchButtonColor;

  @override
  State<StatefulWidget> createState() => _QRViewState();
}

class _QRViewState extends State<QRView> {
  bool isScanMode = true;
  CarouselSlider slider;
  var flareAnimation = "view";

  void openBusinessPhotoUpdatePhotoGallery(BuildContext context) async {
    var image = await (new ImagePicker()).getImage(source: ImageSource.gallery);
    if (image != null) {
      if (!TextUtil.isEmpty(image.path)) {
        try {
          File croppedFile = await ImageCropper.cropImage(
              sourcePath: image.path,
              aspectRatioPresets: [
                CropAspectRatioPreset.square,
                CropAspectRatioPreset.ratio3x2,
                CropAspectRatioPreset.original,
                CropAspectRatioPreset.ratio4x3,
                CropAspectRatioPreset.ratio16x9
              ],
              androidUiSettings: AndroidUiSettings(
                  toolbarTitle: 'Crop your Photo',
                  toolbarColor: Colors.deepOrange,
                  toolbarWidgetColor: Colors.white,
                  showCropGrid: true,
                  initAspectRatio: CropAspectRatioPreset.original,
                  lockAspectRatio: false),
              iosUiSettings: IOSUiSettings(
                minimumAspectRatio: 1.0,
              ));

          if (croppedFile != null) {}
        } catch (issue) {}
      }
    }
  }

  getSlider(BuildContext itemContext) {
    setState(() {
      slider = CarouselSlider(
        height: MediaQuery.of(context).size.height,
        viewportFraction: 1.0,
        enableInfiniteScroll: false,
        onPageChanged: (index) {
          setState(() {
            isScanMode = index == 0;
            if (isScanMode) {
              flareAnimation = "scanToView";
            } else {
              flareAnimation = "viewToScan";
            }
          });
        },
        items: [
          Container(
            alignment: Alignment.center,
            decoration: ShapeDecoration(
              shape: widget.overlay,
            ),
          ),
          Container(
              alignment: Alignment.center,
              decoration: ShapeDecoration(
                shape: widget.overlay,
              ),
              child: GestureDetector(
                onTap: () {
                  openBusinessPhotoUpdatePhotoGallery(itemContext);
                },
                child: Container(
                  width: 240,
                  height: 240,
                  padding: EdgeInsets.all(21),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: widget.qrCodeBackgroundColor,
                  ),
                  child: QrImage(
                    data: widget.data,
                    version: QrVersions.auto,
                    foregroundColor: widget.qrCodeForegroundColor,
                    gapless: true,
                  ),
                ),
              )),
        ],
      );
    });
    return slider;
  }

  GlobalKey<QrcodeReaderViewState> qrViewKey = GlobalKey();

  Future onScan(String data) async {
    await showCupertinoDialog(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: Text("扫码结果"),
          content: Text(data),
          actions: <Widget>[
            CupertinoDialogAction(
              child: Text("确认"),
              onPressed: () => Navigator.pop(context),
            )
          ],
        );
      },
    );
    qrViewKey.currentState.startScan();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _getPlatformQrView(),
        widget.overlay != null ? getSlider(context) : Container(),
        Align(
          alignment: Alignment.topLeft,
          child: SafeArea(
              child: IconButton(
            icon: Icon(
              Icons.clear,
              color: Colors.white70,
            ),
            onPressed: () {
              Navigator.of(context).pop();
            },
          )),
        ),
        Positioned(
          bottom: 16,
          left: 0,
          right: 0,
          child: InkWell(
            onTap: () {
              setState(() {
                isScanMode = !isScanMode;
                if (isScanMode) {
                  flareAnimation = "scanToView";
                  slider?.previousPage(
                      duration: Duration(milliseconds: 500),
                      curve: Curves.linear);
                } else {
                  flareAnimation = "viewToScan";

                  slider?.nextPage(
                      duration: Duration(milliseconds: 500),
                      curve: Curves.linear);
                }
              });
            },
            child: Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(255),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(255),
                child: FlareActor(
                  "packages/twitter_qr_scanner/asset/QRButton.flr",
                  alignment: Alignment.center,
                  animation: flareAnimation,
                  fit: BoxFit.contain,
                  color: widget.switchButtonColor,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _getPlatformQrView() {
    return QrcodeReaderView(key: qrViewKey, onScan: onScan);
  }
}
