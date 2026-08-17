import 'package:flutter/material.dart';
import 'package:kboom/colors.dart';

class VoteBars extends StatelessWidget {
  final int? votesPour;
  final int? votesContre;
  final int? totalVotes;
  final int? totalPlayers;

  const VoteBars({
    super.key,
    required this.votesPour,
    required this.votesContre,
    required this.totalVotes,
    required this.totalPlayers,
  });

  @override
  Widget build(BuildContext context) {
    final double pPour = (votesPour ?? 0).toDouble();
    final double pContre = (votesContre ?? 0).toDouble();
    final double total = pPour + pContre;

    final double percentagePour = total > 0 ? pPour / total : 0.0;
    final double percentageContre = total > 0 ? pContre / total : 0.0;

    return Column(
      children: [
        // La partie avec les barres (on l'enveloppe dans un Expanded pour qu'elle prenne la place)
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildAnimatedBar(context, "OUI", percentagePour, context.successColor),
              const SizedBox(width: 40),
              _buildAnimatedBar(context, "NON", percentageContre, context.dangerColor),
            ],
          ),
        ),

        // Le texte COMMUN en dessous
        Padding(
          padding: const EdgeInsets.only(top: 20),
          child: Text(
            "${totalVotes ?? 0} / ${totalPlayers ?? 0}",
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: context.primaryColor,
            ),
          ),
        ),
      ],
    );
  }

  // La fonction buildBar reste la même, mais SANS le texte du bas
  Widget _buildAnimatedBar(BuildContext context, String label, double targetPourcentage, Color barColor) {
    return Expanded(
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: context.mutedColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutCubic,
                tween: Tween<double>(begin: 0, end: targetPourcentage),
                builder: (context, value, child) {
                  return FractionallySizedBox(
                    alignment: Alignment.bottomCenter,
                    heightFactor: value,
                    child: Container(
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          "${(value * 100).toStringAsFixed(0)}%",
                          style: TextStyle(
                            color: context.modalTextColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 54
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(label, style: TextStyle(fontSize: 18, color: context.primaryColor)),
        ],
      ),
    );
  }
}
