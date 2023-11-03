import 'package:flutter/material.dart';

class StatusBar extends StatelessWidget {
  String _statusMessage;
  StatusBar({required statusMessage}) : _statusMessage = statusMessage;

  @override
  Widget build(BuildContext context) {
    return _buildConnectionStateText(_statusMessage);
  }

  Widget _buildConnectionStateText(String status) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Container(
              color: Colors.amber[200],
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 1),
                child: Text(status,
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                    textAlign: TextAlign.center),
              )),
        ),
      ],
    );
  }
}
