import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart'; // Importa shared_preferences

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
  int highScore = 0; // Variável para armazenar o recorde

  @override
  void initState() {
    super.initState();
    loadHighScore(); // Carrega o recorde ao iniciar
    startGame();
  }

  @override
  void dispose() {
    gameLoop?.cancel();
    super.dispose();
  }

  // Função para carregar o recorde armazenado
  Future<void> loadHighScore() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      highScore = prefs.getInt('highScore') ?? 0;
    });
  }

  // Função para salvar o novo recorde
  Future<void> saveHighScore() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('highScore', highScore);
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
      // Aumenta a pontuação
      score += 1;
      // Adiciona uma nova parte à cobrinha (não remove a última posição)
      snake.add(snake.last);
      // Gera uma nova comida
      generateFood();
      // Verifica se o novo score é maior que o recorde
      if (score > highScore) {
        highScore = score;
        saveHighScore(); // Salva o novo recorde
      }
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

    // Verifica colisão com as paredes
    if (head.dx < 0 ||
        head.dx >= gridSize ||
        head.dy < 0 ||
        head.dy >= gridSize) {
      endGame();
    }

    // Verifica colisão consigo mesma
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
      barrierDismissible: false, // Impede fechar o diálogo tocando fora
      builder: (_) => AlertDialog(
        title: const Text('Game Over'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Sua pontuação: $score'),
            Text('Recorde: $highScore'),
          ],
        ),
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

    // Impede que a cobrinha mude para a direção oposta diretamente
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
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Pontuação: $score',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  Text(
                    'Recorde: $highScore',
                    style: const TextStyle(color: Colors.yellow, fontSize: 14),
                  ),
                ],
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
