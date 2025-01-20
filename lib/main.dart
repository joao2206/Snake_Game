import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math';

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
  final int gridSize = 20;
  List<Offset> snake = [Offset(10, 10)];
  String direction = 'right';
  Timer? gameLoop;
  Offset food = Offset(15, 15);
  bool isGameOver = false;
  int score = 0;

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
        checkCollision();
        checkFood();
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

    snake.add(newHead);
    snake.removeAt(0);
  }

  void checkFood() {
    final head = snake.last;
    if (head == food) {
      score += 1;
      snake.add(snake.last);
      generateFood();
    }
  }

  void generateFood() {
    final random = Random();
    Offset newFood;
    do {
      newFood = Offset(
        random.nextInt(gridSize).toDouble(),
        random.nextInt(gridSize).toDouble(),
      );
    } while (snake.contains(newFood));
    food = newFood;
  }

  void checkCollision() {
    final head = snake.last;

    if (head.dx < 0 ||
        head.dx >= gridSize ||
        head.dy < 0 ||
        head.dy >= gridSize) {
      endGame();
    }

    for (int i = 0; i < snake.length - 1; i++) {
      if (snake[i] == head) {
        endGame();
        break;
      }
    }
  }

  void endGame() {
    gameLoop?.cancel();
    setState(() {
      isGameOver = true;
    });
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Game Over'),
        content: Text('Sua pontuação: $score'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              restartGame();
            },
            child: const Text('Reiniciar'),
          ),
        ],
      ),
    );
  }

  void restartGame() {
    setState(() {
      snake = [Offset(10, 10)];
      direction = 'right';
      score = 0;
      isGameOver = false;
      generateFood();
    });
    startGame();
  }

  void handleKeyPress(LogicalKeyboardKey key) {
    if (isGameOver) return;

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
      appBar: AppBar(
        title: const Text('Jogo da Cobrinha'),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Text(
                'Pontuação: $score',
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ),
        ],
      ),
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
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white),
              ),
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: gridSize * gridSize,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: gridSize,
                ),
                itemBuilder: (BuildContext context, int index) {
                  final x = index % gridSize;
                  final y = index ~/ gridSize;
                  final position = Offset(x.toDouble(), y.toDouble());
                  final isSnake = snake.contains(position);
                  final isFood = position == food;
                  return Container(
                    margin: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: isSnake
                          ? Colors.green
                          : isFood
                              ? Colors.red
                              : Colors.grey[800],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
