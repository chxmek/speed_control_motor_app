import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttermqttnew/modules/core/managers/MQTTManager.dart';
import 'package:fluttermqttnew/modules/core/models/MQTTAppState.dart';
import 'package:fluttermqttnew/modules/core/widgets/status_bar.dart';
import 'package:fluttermqttnew/modules/helpers/screen_route.dart';
import 'package:fluttermqttnew/modules/helpers/status_info_message_utils.dart';
import 'package:provider/provider.dart';

class MessageScreen extends StatefulWidget {
  @override
  _MessageScreenState createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  final TextEditingController _messageTextController = TextEditingController();
  final TextEditingController _topicTextController = TextEditingController();
  final _controller = ScrollController();

  late MQTTManager _manager;

  @override
  void initState() {
    super.initState();
    _topicTextController.text = 'topic/motor';
  }

  @override
  void dispose() {
    _messageTextController.dispose();
    _topicTextController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _manager = Provider.of<MQTTManager>(context);
    if (_controller.hasClients) {
      _controller.jumpTo(_controller.position.maxScrollExtent);
    }

    return Scaffold(
        appBar: _buildAppBar(context) as PreferredSizeWidget?,
        body: _manager.currentState == null
            ? CircularProgressIndicator()
            : _buildColumn(_manager));
  }

  Widget _buildAppBar(BuildContext context) {
    return AppBar(
        elevation: 0,
        backgroundColor: Colors.amber[900],
        title: const Text("Intelligent Speed Controller Motor"),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 15.0),
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).pushNamed(SETTINGS_ROUTE);
              },
              child: Icon(
                Icons.settings,
                size: 26.0,
              ),
            ),
          )
        ]);
  }

  Widget _buildColumn(MQTTManager manager) {
    return Column(
      children: <Widget>[
        StatusBar(
            statusMessage: prepareStateMessageFrom(
                manager.currentState.getAppConnectionState)),
        _buildEditableColumn(manager.currentState),
      ],
    );
  }

  Widget _buildEditableColumn(MQTTAppState currentAppState) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        children: <Widget>[
          _buildScrollableTextWith(currentAppState.getHistoryText),
          const SizedBox(height: 15),
          _buildTopicSubscribeRow(currentAppState),
          const SizedBox(height: 10),
          _buildPublishMessageRow(currentAppState),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildPublishMessageRow(MQTTAppState currentAppState) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        SizedBox(
          width: 220,
          child: _buildTextFieldWith(_messageTextController, 'Enter a message',
              currentAppState.getAppConnectionState),
        ),
        _buildSendButtonFrom(currentAppState.getAppConnectionState)
      ],
    );
  }

  Widget _buildTextFieldWith(TextEditingController controller, String hintText,
      MQTTAppConnectionState state) {
    bool shouldEnable = false;
    if (controller == _messageTextController &&
        state == MQTTAppConnectionState.connectedSubscribed) {
      shouldEnable = true;
    } else if ((controller == _topicTextController &&
        (state == MQTTAppConnectionState.connected ||
            state == MQTTAppConnectionState.connectedUnSubscribed))) {
      shouldEnable = true;
    }
    return TextField(
        enabled: shouldEnable,
        controller: controller,
        decoration: InputDecoration(
          contentPadding:
              const EdgeInsets.only(left: 0, bottom: 0, top: 0, right: 0),
          labelText: hintText,
          labelStyle: TextStyle(color: Colors.black45),
          focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.amber)),
        ));
  }

  Widget _buildSendButtonFrom(MQTTAppConnectionState state) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.amber[900],
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
        disabledForegroundColor: Colors.black38.withOpacity(0.38),
        disabledBackgroundColor: Colors.black38.withOpacity(0.12),
        textStyle: TextStyle(color: Colors.white),
      ),
      child: const Text('Send'),
      onPressed: state == MQTTAppConnectionState.connectedSubscribed
          ? () {
              _publishMessage(_messageTextController.text);
            }
          : null,
    );
  }

  Widget _buildTopicSubscribeRow(MQTTAppState currentAppState) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        SizedBox(
          width: 220,
          child: _buildTextFieldWith(
              _topicTextController,
              'Enter a topic to subscribe',
              currentAppState.getAppConnectionState),
        ),
        _buildSubscribeButtonFrom(currentAppState.getAppConnectionState)
      ],
    );
  }

  Widget _buildSubscribeButtonFrom(MQTTAppConnectionState state) {
    return ElevatedButton(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.amber[900],
          disabledForegroundColor: Colors.grey,
          disabledBackgroundColor: Colors.black38.withOpacity(0.12),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
        ),
        onPressed: (state == MQTTAppConnectionState.connectedSubscribed) ||
                (state == MQTTAppConnectionState.connectedUnSubscribed) ||
                (state == MQTTAppConnectionState.connected)
            ? () {
                _handleSubscribePress(state);
              }
            : null, //,
        child: state == MQTTAppConnectionState.connectedSubscribed
            ? const Text('Unsubscribe')
            : const Text('Subscribe'));
  }

  Widget _buildScrollableTextWith(String text) {
    return Container(
      padding: const EdgeInsets.only(
        left: 15.0,
        right: 5.0,
      ),
      width: double.infinity,
      height: 130,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(7),
        color: Colors.black12,
      ),
      child: SingleChildScrollView(
        controller: _controller,
        child: Text(text, style: TextStyle(fontSize: 13),),
      ),
    );
  }

  void _handleSubscribePress(MQTTAppConnectionState state) {
    if (state == MQTTAppConnectionState.connectedSubscribed) {
      _manager.unSubscribeFromCurrentTopic();
    } else {
      String enteredText = _topicTextController.text;
      if (enteredText != null && enteredText.isNotEmpty) {
        _manager.subScribeTo(_topicTextController.text);
      } else {
        _showDialog("Please enter a topic.");
      }
    }
  }

  void _publishMessage(String text) {
    String osPrefix = 'Mobile';
    if (Platform.isAndroid) {
      osPrefix = 'Mobile';
    }
    final String message = osPrefix + ' : ' + text;
    _manager.publish(message);
    _messageTextController.clear();
  }

  void _showDialog(String message) {
    // flutter defined function
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Error"),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text("Close"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
