import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/level.dart';
import 'package:collection/collection.dart';

enum PowerUpType { aceleracao, desaceleracao, pontuacaoExtra, tamanhoReduzido }

class PowerUp {
  final Offset position;
  final PowerUpType type;

  PowerUp({required this.position, required this.type});
}

class GameScreen extends StatefulWidget {
  const GameScreen({Key? key}) : super(key: key);

  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final int gridSize = 20;
  List<Offset> snake = [const Offset(10, 10)];
  String direction = 'right';
  Timer? gameLoop;
  List<Offset> foods = [];
  List<Offset> obstacles = [];
  List<PowerUp> powerUps = [];
  bool isGameOver = false;
  int score = 0;
  int highScore = 0;
  int currentLevelIndex = 0;

  final List<Level> levels = [
    Level(
      levelNumber: 1,
      speed: const Duration(milliseconds: 300),
      foodCount: 1,
      obstacleCount: 0,
    ),
    Level(
      levelNumber: 2,
      speed: const Duration(milliseconds: 330),
      foodCount: 2,
      obstacleCount: 5,
    ),
    Level(
      levelNumber: 3,
      speed: const Duration(milliseconds: 350),
      foodCount: 3,
      obstacleCount: 10,
    ),
    Level(
      levelNumber: 4,
      speed: const Duration(milliseconds: 350),
      foodCount: 1,
      obstacleCount: 15,
    ),
    Level(
      levelNumber: 5,
      speed: const Duration(milliseconds: 400),
      foodCount: 2,
      obstacleCount: 20,
    ),
    Level(
      levelNumber: 6,
      speed: const Duration(milliseconds: 400),
      foodCount: 3,
      obstacleCount: 25,
    ),
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
    generateFoods(currentLevel.foodCount);
    generateObstacles(currentLevel.obstacleCount);
    generatePowerUps(1);
    gameLoop?.cancel();
    gameLoop = Timer.periodic(currentLevel.speed, (timer) {
      setState(() {
        moveSnake();
        checkCollision();
        checkFood();
        checkPowerUps();
        checkLevelUp();
      });
    });
  }

  void moveSnake() {
    final head = snake.last;
    late Offset newHead;

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
          obstacles.contains(newFood) ||
          powerUps.any((p) => p.position == newFood));
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
          obstacles.contains(newObstacle) ||
          powerUps.any((p) => p.position == newObstacle));
      obstacles.add(newObstacle);
    }
  }

  void generatePowerUps(int count) {
    final random = Random();
    for (int i = 0; i < count; i++) {
      Offset newPowerUp;
      do {
        newPowerUp = Offset(
          random.nextInt(gridSize).toDouble(),
          random.nextInt(gridSize).toDouble(),
        );
      } while (snake.contains(newPowerUp) ||
          foods.contains(newPowerUp) ||
          obstacles.contains(newPowerUp) ||
          powerUps.any((p) => p.position == newPowerUp));

      PowerUpType type =
          PowerUpType.values[random.nextInt(PowerUpType.values.length)];
      powerUps.add(PowerUp(position: newPowerUp, type: type));
    }
  }

  void checkPowerUps() {
    final head = snake.last;
    final index = powerUps.indexWhere((p) => p.position == head);
    if (index != -1) {
      final powerUp = powerUps.removeAt(index);
      applyPowerUp(powerUp);
    }
  }

  void applyPowerUp(PowerUp powerUp) {
    switch (powerUp.type) {
      case PowerUpType.aceleracao:
        final oldSpeed = levels[currentLevelIndex].speed;
        changeGameSpeed(
            Duration(milliseconds: (oldSpeed.inMilliseconds * 0.7).toInt()));
        Future.delayed(const Duration(seconds: 5), () {
          changeGameSpeed(oldSpeed);
        });
        break;
      case PowerUpType.desaceleracao:
        final oldSpeed = levels[currentLevelIndex].speed;
        changeGameSpeed(
            Duration(milliseconds: (oldSpeed.inMilliseconds * 1.3).toInt()));
        Future.delayed(const Duration(seconds: 5), () {
          changeGameSpeed(oldSpeed);
        });
        break;
      case PowerUpType.pontuacaoExtra:
        setState(() {
          score += 5;
          if (score > highScore) {
            highScore = score;
            saveHighScore();
          }
        });
        break;
      case PowerUpType.tamanhoReduzido:
        setState(() {
          if (snake.length > 3) {
            snake.removeRange(0, snake.length ~/ 2);
          }
        });
        break;
    }
  }

  void changeGameSpeed(Duration newSpeed) {
    final currentLevel = levels[currentLevelIndex];
    gameLoop?.cancel();
    gameLoop = Timer.periodic(newSpeed, (timer) {
      setState(() {
        moveSnake();
        checkCollision();
        checkFood();
        checkPowerUps();
        checkLevelUp();
      });
    });
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
          title: const Text('NEXT LEVEL!'),
          content: Text(
            'Você avançou para o nível ${levels[currentLevelIndex + 1].levelNumber}!',
          ),
        ),
      );

      Future.delayed(const Duration(seconds: 1), () {
        Navigator.of(context).pop();
        setState(() {
          currentLevelIndex += 1;
          initializeLevel();
        });
      });
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
      snake = [const Offset(10, 10)];
      direction = 'right';
      score = 0;
      isGameOver = false;
      currentLevelIndex = 0;
      foods.clear();
      obstacles.clear();
      powerUps.clear();
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
                  Text('Pontuação: $score',
                      style:
                          const TextStyle(color: Colors.white, fontSize: 16)),
                  Text('Recorde: $highScore',
                      style:
                          const TextStyle(color: Colors.yellow, fontSize: 14)),
                  Text('Nível: ${levels[currentLevelIndex].levelNumber}',
                      style:
                          const TextStyle(color: Colors.white, fontSize: 16)),
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
                  final PowerUp? powerUp =
                      powerUps.firstWhereOrNull((p) => p.position == position);
                  Color cellColor = Colors.grey[800]!;
                  if (isSnake) {
                    cellColor = Colors.green;
                  } else if (isFood) {
                    cellColor = Colors.red;
                  } else if (isObstacle) {
                    cellColor = Colors.grey;
                  } else if (powerUp != null) {
                    switch (powerUp.type) {
                      case PowerUpType.aceleracao:
                        cellColor = Colors.purple;
                        break;
                      case PowerUpType.desaceleracao:
                        cellColor = Colors.blue;
                        break;
                      case PowerUpType.pontuacaoExtra:
                        cellColor = Colors.orange;
                        break;
                      case PowerUpType.tamanhoReduzido:
                        cellColor = Colors.teal;
                        break;
                    }
                  }
                  return Container(
                    margin: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: cellColor,
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
