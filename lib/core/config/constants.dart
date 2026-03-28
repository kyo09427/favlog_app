class Constants {
  static const String siteUrl = 'https://favlog.okasis.win/';
  static const String customScheme = 'com.example.favlog_app://';
  static const String discordTargetGuildId = String.fromEnvironment(
    'DISCORD_TARGET_GUILD_ID',
    defaultValue: '',
  );
}
