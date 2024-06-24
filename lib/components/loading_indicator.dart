
import 'package:flutter/material.dart';
class LoadingIndicator extends StatefulWidget {
  final VoidCallback onPressed;
  MaterialColor color;

  LoadingIndicator({required this.onPressed, required MaterialColor this.color});

  @override
  _LoadingIndicatorState createState() => _LoadingIndicatorState();
}

class _LoadingIndicatorState extends State<LoadingIndicator> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: 10)).then((_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? Container(
      margin: EdgeInsets.only(top: 8.0, bottom: 8.0),
          child: CircularProgressIndicator(
                color: widget.color,
              ),
        )
        : Column(
            children: [
              Text("Không tìm thấy đường đi"),
              ElevatedButton(
                onPressed: widget.onPressed,
                child: Text("Trở về"),
              ),
            ],
          );
  }
}