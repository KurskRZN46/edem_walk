// Каталог аватаров приложения.
// Все изображения — авторские, сгенерированы специально для приложения
// (стилизованные вымышленные персонажи, НЕ реальные футболисты),
// поэтому проблем с авторскими правами нет.

class PlayerAvatar {
  final String id;
  final String name; // игровое имя персонажа
  final String title; // короткая роль
  final String asset; // путь к картинке

  const PlayerAvatar({
    required this.id,
    required this.name,
    required this.title,
    required this.asset,
  });
}

const List<PlayerAvatar> playerAvatars = [
  PlayerAvatar(
    id: 'striker',
    name: 'Бомбардир',
    title: 'Девятка',
    asset: 'assets/avatars/avatar_striker.png',
  ),
  PlayerAvatar(
    id: 'keeper',
    name: 'Стена',
    title: 'Вратарь',
    asset: 'assets/avatars/avatar_keeper.png',
  ),
  PlayerAvatar(
    id: 'playmaker',
    name: 'Плеймейкер',
    title: 'Десятка',
    asset: 'assets/avatars/avatar_playmaker.png',
  ),
  PlayerAvatar(
    id: 'defender',
    name: 'Опорник',
    title: 'Защитник',
    asset: 'assets/avatars/avatar_defender.png',
  ),
  PlayerAvatar(
    id: 'captain',
    name: 'Капитан',
    title: 'Лидер',
    asset: 'assets/avatars/avatar_captain.png',
  ),
  PlayerAvatar(
    id: 'winger',
    name: 'Экспресс',
    title: 'Вингер',
    asset: 'assets/avatars/avatar_winger.png',
  ),
  PlayerAvatar(
    id: 'veteran',
    name: 'Профессор',
    title: 'Ветеран',
    asset: 'assets/avatars/avatar_veteran.png',
  ),
  PlayerAvatar(
    id: 'street',
    name: 'Уличный',
    title: 'Фристайлер',
    asset: 'assets/avatars/avatar_street.png',
  ),
];

// Поиск аватара по id; если не найден - первый в списке
PlayerAvatar avatarById(String id) {
  for (final a in playerAvatars) {
    if (a.id == id) return a;
  }
  return playerAvatars.first;
}
