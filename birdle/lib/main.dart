import 'package:flutter/material.dart';

import 'game.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Birdle',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        useMaterial3: false,
      ),
      home: const GamePage(),
    );
  }
}

// ---------------------------------------------------------------------------
// Tile
// ---------------------------------------------------------------------------

class Tile extends StatelessWidget {
  const Tile(this.letter, this.hitType, {super.key});

  final String letter;
  final HitType hitType;

  @override
  Widget build(BuildContext context) {
    final color = switch (hitType) {
      HitType.hit => Colors.green.shade600,
      HitType.partial => Colors.amber.shade600,
      HitType.miss => Colors.grey.shade600,
      _ => Colors.white,
    };

    final textColor = hitType == HitType.none ? Colors.black87 : Colors.white;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutBack,
      height: 60,
      width: 60,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          letter.toUpperCase(),
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(color: textColor, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// GamePage
// ---------------------------------------------------------------------------

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  Game _game = Game();

  void _resetGame() {
    setState(() {
      _game = Game();
    });
  }

  @override
  Widget build(BuildContext context) {
    final gameOver = _game.didWin || _game.didLose;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Birdle'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Начать заново',
            icon: const Icon(Icons.refresh),
            onPressed: _resetGame,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Осталось попыток: ${_game.guessesRemaining}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            for (var guess in _game.guesses)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var letter in guess)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 3,
                        vertical: 3,
                      ),
                      child: Tile(letter.char, letter.type),
                    ),
                ],
              ),
            const Spacer(),
            if (gameOver) _ResultBanner(game: _game, onRestart: _resetGame),
            if (!gameOver)
              GuessInput(
                isLegalGuess: _game.isLegalGuess,
                onSubmitGuess: (String guess) {
                  setState(() {
                    _game.guess(guess);
                  });
                },
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ResultBanner
// ---------------------------------------------------------------------------

class _ResultBanner extends StatelessWidget {
  const _ResultBanner({required this.game, required this.onRestart});

  final Game game;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    final won = game.didWin;
    final color = won ? Colors.green.shade600 : Colors.red.shade600;
    final message = won ? 'Победа!' : 'Поражение';

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color, width: 2),
          ),
          child: Column(
            children: [
              Text(
                message,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(color: color, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Загаданное слово: ${game.hiddenWord.toString().toUpperCase()}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: onRestart,
          icon: const Icon(Icons.replay),
          label: const Text('Играть снова'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// GuessInput
// ---------------------------------------------------------------------------

class GuessInput extends StatefulWidget {
  const GuessInput({
    super.key,
    required this.onSubmitGuess,
    required this.isLegalGuess,
  });

  final void Function(String) onSubmitGuess;
  final bool Function(String) isLegalGuess;

  @override
  State<GuessInput> createState() => _GuessInputState();
}

class _GuessInputState extends State<GuessInput> {
  final TextEditingController _textEditingController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String? _errorText;

  @override
  void dispose() {
    _textEditingController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSubmit() {
    final input = _textEditingController.text.trim().toLowerCase();

    if (input.length != 5) {
      setState(() => _errorText = 'Нужно ровно 5 букв');
      return;
    }
    if (!widget.isLegalGuess(input)) {
      setState(() => _errorText = 'Слово не из словаря');
      return;
    }

    setState(() => _errorText = null);
    widget.onSubmitGuess(input);
    _textEditingController.clear();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              maxLength: 5,
              focusNode: _focusNode,
              autofocus: true,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                errorText: _errorText,
                counterText: '',
                hintText: 'Введите слово',
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(35)),
                ),
              ),
              controller: _textEditingController,
              onSubmitted: (_) => _onSubmit(),
              onChanged: (_) {
                if (_errorText != null) {
                  setState(() => _errorText = null);
                }
              },
            ),
          ),
        ),
        IconButton(
          iconSize: 40,
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.arrow_circle_up),
          onPressed: _onSubmit,
        ),
      ],
    );
  }
}