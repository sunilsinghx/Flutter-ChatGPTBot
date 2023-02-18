import 'dart:async';

import 'package:flutter/material.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'token.dart';

import 'chatmessage.dart';

class chatscreen extends StatefulWidget {
  const chatscreen({super.key});

  @override
  State<chatscreen> createState() => _chatscreenState();
}

class _chatscreenState extends State<chatscreen> {
  bool istyping = false;
  List<ChatMessage> msg = [];
  final TextEditingController _controller = TextEditingController();
  OpenAI? chatGPT;
  StreamSubscription? _subscription;

  void _sendmessage() {
    ChatMessage _message = ChatMessage(text: _controller.text, sender: "user");
    setState(() {
      if (_controller.text.isEmpty) {
        return;
      } else {
        istyping = true;
        msg.insert(0, _message);
      }
    });

    _controller.clear();

    _botmsgsend(_message);
  }

  void _botmsgsend(ChatMessage _message) {
    final request = CompleteText(
      prompt: _message.text,
      model: kTranslateModelV2,
      maxTokens: 200,
    );

    _subscription = chatGPT
        ?.build(token: Token.token)
        .onCompleteStream(request: request)
        .listen((response) {
      Vx.log(response);
      if (response != null && msg[0].text != response.choices[0].text) {
        ChatMessage botmsg =
            ChatMessage(text: response.choices[0].text, sender: "bot");

        setState(() {
          istyping = false;
          if (botmsg.text.isNotEmpty) {
            msg.insert(0, botmsg);
          }
        });
      } else {
        return;
        // if (response == null) {
        //   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        //       content: Text("Something went wront try it latter")));
        // } else if (msg[0].text == response.choices[0].text) {
        //   return;
        // }
      }
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    chatGPT = OpenAI.instance;
  }

  void despose() {
    _subscription?.cancel();
    chatGPT?.close();
    super.dispose();
  }

  Widget _buildtextComposer() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            onSubmitted: (value) => _sendmessage(),
            controller: _controller,
            decoration:
                const InputDecoration.collapsed(hintText: "send a message"),
          ),
        ),
        IconButton(
          onPressed: _sendmessage,
          icon: const Icon(Icons.send),
        ),
      ],
    ).px8();
  }

//display ChatMessage
  Widget DisplayChatMsg() {
    return Flexible(
      child: ListView.builder(
        itemCount: msg.length,
        padding: Vx.m8,
        reverse: true,
        itemBuilder: ((context, index) {
          return msg[index];
        }),
      ),
    );
  }

//loading widget
  Widget loadingWidget() {
    return Visibility(
      visible: istyping,
      child: Image.asset(
        alignment: Alignment(0, 0),
        "assets/loading2.gif",
        width: 100,

        // fit: BoxFit.fitWidth,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ChatGPT"),
      ),
      body: SafeArea(
          child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            msg.isNotEmpty
                ? DisplayChatMsg()
                : const Flexible(
                    child: Center(
                      child: Text(
                        "How Can we help you?",
                        style: TextStyle(
                          fontSize: 28,
                          backgroundColor: Colors.amber,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

            loadingWidget(),

            const Divider(
              height: 1,
            ),
            //display fextfelid ,send icon

            Container(
              decoration: BoxDecoration(
                color: context.cardColor,
              ),
              child: _buildtextComposer(),
            )
          ],
        ),
      )),
    );
  }
}
