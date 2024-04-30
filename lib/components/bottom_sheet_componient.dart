import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:voyageventure/components/mock_list.dart';

import 'fonts.dart';

class BottomSheetComponient_ extends StatefulWidget {
  ScrollController controller;

  BottomSheetComponient_({Key? key, required this.controller})
      : super(key: key);

  @override
  State<BottomSheetComponient_> createState() => _BottomSheetComponient_State();
}


class _BottomSheetComponient_State extends State<BottomSheetComponient_> {
  bool isNullCollection = true;
  bool isNull2 = true;

  @override
  Widget build(BuildContext context) {
    return Container(
        // Gray card
        padding: const EdgeInsets.all(20),
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFFF0F0F0),
          borderRadius: BorderRadius.all(Radius.circular(20.0)),
        ),
        child: Column(
          //BST, BDNT
          children: [
            DecoratedBox(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(20.0)),
              ),
              child: Container(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.only(left: 8),
                      alignment: Alignment.topLeft,
                      child: Text(
                        'ĐỊA ĐIỂM ĐÃ LƯU',
                        style: leagueSpartanTitle,
                      ),
                    ),
                    isNullCollection
                        ? Container(
                            //padding: const EdgeInsets.only(left: 200),
                            alignment: Alignment.centerRight,
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      isNullCollection = false;
                                    });
                                  },
                                  child: Image(
                                    image: AssetImage('assets/collection.jpg'),
                                    width:
                                        MediaQuery.of(context).size.width * 0.3,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    'Lưu những địa điểm bạn thích và mang chúng theo khắp mọi nơi.',
                                    style: leagueSpartanParagraph,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : MockList_(controller: widget.controller),
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: SvgPicture.asset('assets/icons/pluss.svg'),
                      label: Text('Thêm địa điểm', style: leagueSpartanBlue,),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          elevation: 0,
                          fixedSize: const Size(double.infinity, 40)
                      ),)
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            DecoratedBox(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(20.0)),
              ),
              child: Container(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.only(left: 8),
                      alignment: Alignment.topLeft,
                      child: Text(
                        'TÀI KHOẢN & CÀI ĐẶT',
                        style: leagueSpartanTitle,
                      ),
                    ),
                    isNull2
                        ? Container(
                            //padding: const EdgeInsets.only(left: 200),
                            alignment: Alignment.centerRight,
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      isNull2 = false;
                                    });
                                  },
                                  child: Image(
                                    image: AssetImage('assets/collection.jpg'),
                                    width:
                                        MediaQuery.of(context).size.width * 0.3,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    'Lưu những địa điểm bạn thích và mang chúng theo khắp mọi nơi.',
                                    style: leagueSpartanParagraph,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : MockList_(controller: widget.controller),
                  ],
                ),
              ),
            ),
          ],
        ));
  }
}
