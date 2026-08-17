String formatPlayerStatusLabel({
  required bool isCurrentTurnPlayer,
  required bool isEliminated,
}) {
  if (isEliminated) {
    return 'Éliminé';
  }
  if (isCurrentTurnPlayer) {
    return 'Tour en cours';
  }
  return 'En jeu';
}
