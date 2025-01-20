import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

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

class Level {
  final int levelNumber;
  final Duration speed;
  final int foodCount;
  final int obstacleCount;

  Level({
    required this.levelNumber,
    required this.speed,
    required this.foodCount,
    required this.obstacleCount,
  });
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
  List<Offset> foods = [];
  List<Offset> obstacles = [];
  bool isGameOver = false;
  int score = 0;
  int highScore = 0;
  int currentLevelIndex = 0;

  List<Level> levels = [
    Level(
        levelNumber: 1,
        speed: Duration(milliseconds: 300),
        foodCount: 1,
        obstacleCount: 0),
    Level(
        levelNumber: 2,
        speed: Duration(milliseconds: 250),
        foodCount: 2,
        obstacleCount: 5),
    Level(
        levelNumber: 3,
        speed: Duration(milliseconds: 200),
        foodCount: 3,
        obstacleCount: 10),
  ];

  @override
  void initState() {
    super.initState();
    loadHighScore();
    initializeLevel();
  }

  @override
  void dispose() {
    gameLoop?.cancel();
    super.dispose();
  }

  Future<void> loadHighScore() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      highScore = prefs.getInt('highScore') ?? 0;
    });
  }

  Future<void> saveHighScore() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('highScore', highScore);
  }

  void initializeLevel() {
    final currentLevel = levels[currentLevelIndex];
    generateObstacles(currentLevel.obstacleCount);
    generateFoods(currentLevel.foodCount);
    gameLoop?.cancel();
    gameLoop = Timer.periodic(currentLevel.speed, (timer) {
      setState(() {
        moveSnake();
        checkCollision();
        checkFood();
        checkLevelUp();
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
    if (foods.contains(head)) {
      setState(() {
        foods.remove(head);
        score += 1;
        snake.add(snake.last);
        final currentLevel = levels[currentLevelIndex];
        generateFoods(1);
        if (score > highScore) {
          highScore = score;
          saveHighScore();
        }
      });
    }
  }

  void generateFoods(int count) {
    final random = Random();
    for (int i = 0; i < count; i++) {
      Offset newFood;
      do {
        newFood = Offset(
          random.nextInt(gridSize).toDouble(),
          random.nextInt(gridSize).toDouble(),
        );
      } while (snake.contains(newFood) ||
          foods.contains(newFood) ||
          obstacles.contains(newFood));
      foods.add(newFood);
    }
  }

  void generateObstacles(int count) {
    final random = Random();
    obstacles.clear();
    for (int i = 0; i < count; i++) {
      Offset newObstacle;
      do {
        newObstacle = Offset(
          random.nextInt(gridSize).toDouble(),
          random.nextInt(gridSize).toDouble(),
        );
      } while (snake.contains(newObstacle) ||
          foods.contains(newObstacle) ||
          obstacles.contains(newObstacle));
      obstacles.add(newObstacle);
    }
  }

  void checkCollision() {
    final head = snake.last;

    if (head.dx < 0 ||
        head.dx >= gridSize ||
        head.dy < 0 ||
        head.dy >= gridSize) {
      endGame();
      return;
    }

    for (int i = 0; i < snake.length - 1; i++) {
      if (snake[i] == head) {
        endGame();
        return;
      }
    }

    if (obstacles.contains(head)) {
      endGame();
      return;
    }
  }

  void checkLevelUp() {
    int levelUpScore = (currentLevelIndex + 1) * 5;
    if (score >= levelUpScore && currentLevelIndex < levels.length - 1) {
      gameLoop?.cancel();

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text('Nível Up!'),
          content: Text(
            'Você avançou para o nível ${levels[currentLevelIndex + 1].levelNumber}!',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  currentLevelIndex += 1;
                  initializeLevel();
                });
              },
              child: const Text('Continuar'),
            ),
          ],
        ),
      );
    }
  }

  void endGame() {
    gameLoop?.cancel();
    setState(() {
      isGameOver = true;
    });
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Game Over'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Sua pontuação: $score'),
            Text('Recorde: $highScore'),
            Text('Nível alcançado: ${levels[currentLevelIndex].levelNumber}'),
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
      currentLevelIndex = 0;
      obstacles.clear();
      foods.clear();
      initializeLevel();
    });
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
                  Text(
                    'Nível: ${levels[currentLevelIndex].levelNumber}',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
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
                  final isFood = foods.contains(position);
                  final isObstacle = obstacles.contains(position);
                  return Container(
                    margin: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: isSnake
                          ? Colors.green
                          : isFood
                              ? Colors.red
                              : isObstacle
                                  ? Colors.grey
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
