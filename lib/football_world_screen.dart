import 'package:flutter/material.dart';
import '../data/football_facts.dart';
import '../data/football_quiz.dart';

// Экран «Мир футбола»: факт дня + энциклопедия + викторина.
class FootballWorldScreen extends StatefulWidget {
  const FootballWorldScreen({super.key});

  @override
  State<FootballWorldScreen> createState() => _FootballWorldScreenState();
}

class _FootballWorldScreenState extends State<FootballWorldScreen> {
  int _tab = 0;

  static const _tabs = [
    'Термины', 'Тактика', 'Рекорды', 'Стадионы', 'Клубы', 'История', 'Викторина'
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const green = Color(0xFF00C853);
    const red = Color(0xFFFF1744);
    final cardColor = isDark ? const Color(0xFF151B23) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF1E2730) : const Color(0xFFD0D5DD);
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final subColor =
        isDark ? const Color(0xFF8B95A7) : const Color(0xFF5A6577);

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0B0F14) : const Color(0xFFF8F9FB),
      body: SafeArea(
        child: Column(
          children: [
            _WorldHeader(isDark: isDark, theme: theme),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ФАКТ ДНЯ
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? [const Color(0xFF102218), const Color(0xFF151B23)]
                            : [const Color(0xFFD7FFE6), Colors.white],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: green.withValues(alpha: 0.4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.lightbulb, size: 18, color: green),
                            SizedBox(width: 8),
                            Text(
                              'Факт дня',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: green,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          factOfTheDay(),
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.45,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // ПЕРЕКЛЮЧАТЕЛЬ РАЗДЕЛОВ
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (int i = 0; i < _tabs.length; i++) ...[
                          GestureDetector(
                            onTap: () => setState(() => _tab = i),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 9),
                              decoration: BoxDecoration(
                                color: _tab == i ? red : cardColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _tab == i ? red : borderColor,
                                ),
                              ),
                              child: Text(
                                _tabs[i],
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: _tab == i ? Colors.white : textColor,
                                ),
                              ),
                            ),
                          ),
                          if (i < _tabs.length - 1) const SizedBox(width: 8),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  // КОНТЕНТ ВКЛАДКИ
                  if (_tab == 0) _TermsList(cardColor, borderColor, textColor, subColor, isDark),
                  if (_tab == 1) _TacticsList(cardColor, borderColor, textColor, subColor, isDark),
                  if (_tab == 2) _RecordsList(cardColor, borderColor, textColor, subColor, isDark),
                  if (_tab == 3) _StadiumsList(cardColor, borderColor, textColor, subColor, isDark),
                  if (_tab == 4) _ClubsList(cardColor, borderColor, textColor, subColor, isDark),
                  if (_tab == 5) _HistoryList(cardColor, borderColor, textColor, subColor, isDark),
                  if (_tab == 6) _QuizView(cardColor, borderColor, textColor, subColor, isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Тактика: карточки схем
class _TacticsList extends StatelessWidget {
  final Color cardColor, borderColor, textColor, subColor;
  final bool isDark;
  const _TacticsList(this.cardColor, this.borderColor, this.textColor,
      this.subColor, this.isDark);

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF00C853);
    return Column(
      children: [
        for (final t in footballTactics)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.grid_on, size: 20, color: green),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.name,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        t.description,
                        style: TextStyle(
                            fontSize: 12.5, height: 1.4, color: subColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// Стадионы мира
class _StadiumsList extends StatelessWidget {
  final Color cardColor, borderColor, textColor, subColor;
  final bool isDark;
  const _StadiumsList(this.cardColor, this.borderColor, this.textColor,
      this.subColor, this.isDark);

  @override
  Widget build(BuildContext context) {
    const red = Color(0xFFFF1744);
    return Column(
      children: [
        for (final s in footballStadiums)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.stadium, size: 22, color: red),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.name,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                      ),
                      Text(
                        s.city,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: red,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        s.fact,
                        style: TextStyle(
                            fontSize: 12.5, height: 1.4, color: subColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// Легендарные клубы
class _ClubsList extends StatelessWidget {
  final Color cardColor, borderColor, textColor, subColor;
  final bool isDark;
  const _ClubsList(this.cardColor, this.borderColor, this.textColor,
      this.subColor, this.isDark);

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF00C853);
    return Column(
      children: [
        for (final c in legendaryClubs)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.shield, size: 22, color: green),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.name,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                      ),
                      Text(
                        c.country,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: green,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        c.fact,
                        style: TextStyle(
                            fontSize: 12.5, height: 1.4, color: subColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// Список терминов
class _TermsList extends StatelessWidget {
  final Color cardColor, borderColor, textColor, subColor;
  final bool isDark;
  const _TermsList(this.cardColor, this.borderColor, this.textColor,
      this.subColor, this.isDark);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final t in footballTerms)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.term,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  t.definition,
                  style: TextStyle(fontSize: 12.5, height: 1.4, color: subColor),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// Список рекордов
class _RecordsList extends StatelessWidget {
  final Color cardColor, borderColor, textColor, subColor;
  final bool isDark;
  const _RecordsList(this.cardColor, this.borderColor, this.textColor,
      this.subColor, this.isDark);

  @override
  Widget build(BuildContext context) {
    const red = Color(0xFFFF1744);
    return Column(
      children: [
        for (final r in footballRecords)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                const Icon(Icons.emoji_events, size: 22, color: red),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.title,
                        style: TextStyle(fontSize: 11.5, color: subColor),
                      ),
                      Text(
                        r.holder,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  r.value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: red,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// История: таймлайн
class _HistoryList extends StatelessWidget {
  final Color cardColor, borderColor, textColor, subColor;
  final bool isDark;
  const _HistoryList(this.cardColor, this.borderColor, this.textColor,
      this.subColor, this.isDark);

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF00C853);
    return Column(
      children: [
        for (int i = 0; i < footballHistory.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Линия таймлайна с точкой
                Column(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.only(top: 6),
                      decoration: const BoxDecoration(
                        color: green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    if (i < footballHistory.length - 1)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: green.withValues(alpha: 0.3),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          footballHistory[i].year,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: green,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          footballHistory[i].event,
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.4,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// Викторина
class _QuizView extends StatefulWidget {
  final Color cardColor, borderColor, textColor, subColor;
  final bool isDark;
  const _QuizView(this.cardColor, this.borderColor, this.textColor,
      this.subColor, this.isDark);

  @override
  State<_QuizView> createState() => _QuizViewState();
}

class _QuizViewState extends State<_QuizView> {
  int _current = 0; // текущий вопрос
  int _score = 0; // правильных ответов
  int? _picked; // выбранный вариант (null - ещё не отвечал)
  bool _finished = false;

  void _answer(int i) {
    if (_picked != null) return; // уже ответил на этот вопрос
    setState(() {
      _picked = i;
      if (i == footballQuiz[_current].correctIndex) _score++;
    });
    // Через секунду - следующий вопрос
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() {
        if (_current < footballQuiz.length - 1) {
          _current++;
          _picked = null;
        } else {
          _finished = true;
        }
      });
    });
  }

  void _restart() {
    setState(() {
      _current = 0;
      _score = 0;
      _picked = null;
      _finished = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF00C853);
    const red = Color(0xFFFF1744);

    if (_finished) {
      final percent = _score / footballQuiz.length;
      final (emoji, verdict) = percent >= 0.9
          ? ('🏆', 'Легенда футбола!')
          : percent >= 0.6
              ? ('⚽', 'Уверенный игрок!')
              : ('📚', 'Загляни в раздел «Термины»!');
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: widget.cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: green.withValues(alpha: 0.5), width: 2),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 52)),
            const SizedBox(height: 10),
            Text(
              verdict,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: widget.textColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Правильных ответов: $_score из ${footballQuiz.length}',
              style: TextStyle(fontSize: 14, color: widget.subColor),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: red),
              onPressed: _restart,
              icon: const Icon(Icons.replay),
              label: const Text('Играть снова'),
            ),
          ],
        ),
      );
    }

    final q = footballQuiz[_current];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Прогресс викторины
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Вопрос ${_current + 1} из ${footballQuiz.length}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: widget.subColor,
              ),
            ),
            Text(
              'Счёт: $_score',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: _current / footballQuiz.length,
            minHeight: 5,
            backgroundColor: widget.isDark
                ? const Color(0xFF1E2730)
                : const Color(0xFFE8ECF1),
            valueColor: const AlwaysStoppedAnimation<Color>(green),
          ),
        ),
        const SizedBox(height: 14),
        // Вопрос
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: widget.borderColor),
          ),
          child: Text(
            q.question,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: widget.textColor,
              height: 1.35,
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Варианты ответов
        for (int i = 0; i < q.options.length; i++) ...[
          Builder(builder: (context) {
            Color bg = widget.cardColor;
            Color border = widget.borderColor;
            if (_picked != null) {
              if (i == q.correctIndex) {
                bg = green.withValues(alpha: 0.15);
                border = green;
              } else if (i == _picked) {
                bg = red.withValues(alpha: 0.12);
                border = red;
              }
            }
            return GestureDetector(
              onTap: () => _answer(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 13),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: border, width: 1.5),
                ),
                child: Text(
                  q.options[i],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: widget.textColor,
                  ),
                ),
              ),
            );
          }),
          if (i < q.options.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

// Хедер экрана
class _WorldHeader extends StatelessWidget {
  final bool isDark;
  final ThemeData theme;

  const _WorldHeader({required this.isDark, required this.theme});

  @override
  Widget build(BuildContext context) {
    const red = Color(0xFFFF1744);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151B23) : const Color(0xFFE8ECF1),
        border: Border(
          bottom: BorderSide(color: red.withValues(alpha: 0.6), width: 2),
        ),
        boxShadow: [
          BoxShadow(
            color: red.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new,
                size: 18,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Text(
            'Мир футбола',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              fontSize: 17,
              letterSpacing: 0.3,
              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
            ),
          ),
        ],
      ),
    );
  }
}
