import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import necessário para LogicalKeyboardKey
import 'dart:async';

void main() {
  runApp(const SnakeGame());
}

class SnakeGame extends StatelessWidget {
  const SnakeGame({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  List<Offset> snake = [const Offset(0, 0)];
  String direction = 'right';
  Timer? gameLoop;

  @override
  void initState() {
    super.initState();
    startGame();
  }

  @override
  void dispose() {
    gameLoop?.cancel();
    super.dispose();
  }

  void startGame() {
    gameLoop = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      setState(() {
        moveSnake();
      });
    });
  }

  void moveSnake() {
    final head = snake.last;
    Offset newHead;

    switch (direction) {
      case 'up':
        newHead = head + const Offset(0, -1);
        break;
      case 'down':
        newHead = head + const Offset(0, 1);
        break;
      case 'left':
        newHead = head + const Offset(-1, 0);
        break;
      case 'right':
      default:
        newHead = head + const Offset(1, 0);
    }

    setState(() {
      snake.add(newHead);
      snake.removeAt(0);
    });
  }

  void handleKeyPress(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.arrowUp && direction != 'down') {
      direction = 'up';
    } else if (key == LogicalKeyboardKey.arrowDown && direction != 'up') {
      direction = 'down';
    } else if (key == LogicalKeyboardKey.arrowLeft && direction != 'right') {
      direction = 'left';
    } else if (key == LogicalKeyboardKey.arrowRight && direction != 'left') {
      direction = 'right';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Focus(
        autofocus: true,
        onKey: (FocusNode node, RawKeyEvent event) {
          if (event is RawKeyDownEvent) {
            handleKeyPress(event.logicalKey);
          }
          return KeyEventResult.handled;
        },
        child: Center(
          child: AspectRatio(
            aspectRatio: 1,
            child: GridView.builder(
              itemCount: 20 * 20,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 20,
              ),
              itemBuilder: (BuildContext context, int index) {
                final x = index % 20;
                final y = index ~/ 20;
                final isSnake =
                    snake.contains(Offset(x.toDouble(), y.toDouble()));
                return Container(
                  margin: const EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    color: isSnake ? Colors.green : Colors.grey[800],
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
