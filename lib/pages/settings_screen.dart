import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:start_on/services/notion_sync_service.dart';
import 'package:start_on/storage/app_settings_store.dart';
import 'package:start_on/storage/local_data_store.dart';
import 'package:start_on/widgets/common.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AppSettingsStore _settingsStore = const AppSettingsStore();
  final LocalDataStore _localDataStore = const LocalDataStore();
  final NotionSyncService _notionSyncService = const NotionSyncService();

  bool _notificationsEnabled = true;
  bool _vibrationEnabled = true;
  bool _celebrationEffectEnabled = true;
  bool _autoSaveEnabled = true;
  bool _isNotionSyncEnabled = false;
  bool _isNotionSyncBusy = false;
  String _notionDatabaseId = '';
  String _notionDatabaseTitle = '';
  String _notionApiTokenDraft = '';
  String _notionDatabaseInputDraft = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFF),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFF8EF), Color(0xFFF7FBFF), Color(0xFFFFF0F3)],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 32),
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    '환경설정',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1C2940),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              RoundedCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeading(
                      icon: Icons.tune_rounded,
                      title: '앱 설정',
                    ),
                    const SizedBox(height: 14),
                    _SettingsSwitchTile(
                      icon: Icons.calendar_today_outlined,
                      title: '노션 캘린더 연결',
                      subtitle: '노션캘린더 연결로 할일 자동 가져오기',
                      value: _isNotionSyncEnabled,
                      onChanged: _isNotionSyncBusy
                          ? null
                          : _handleNotionCalendarToggle,
                    ),
                    if (_isNotionSyncEnabled) ...[
                      const SizedBox(height: 10),
                      _SettingsActionTile(
                        icon: Icons.sync_rounded,
                        title: _notionDatabaseTitle.isEmpty
                            ? 'Notion 연동됨'
                            : _notionDatabaseTitle,
                        subtitle: _notionDatabaseId.isEmpty
                            ? '등록된 데이터베이스 없음'
                            : _notionDatabaseId,
                        buttonLabel: _isNotionSyncBusy ? '동기화 중...' : '지금 가져오기',
                        onPressed: _isNotionSyncBusy ? null : _syncNotionTasks,
                      ),
                    ],
                    const SizedBox(height: 14),
                    _SettingsSwitchTile(
                      icon: Icons.notifications_none_rounded,
                      title: '알림 받기',
                      subtitle: '퀘스트 진행과 리마인더 알림',
                      value: _notificationsEnabled,
                      onChanged: _updateNotificationsEnabled,
                    ),
                    const SizedBox(height: 10),
                    _SettingsSwitchTile(
                      icon: Icons.vibration_rounded,
                      title: '진동',
                      subtitle: '버튼 클릭과 완료 시 진동 피드백',
                      value: _vibrationEnabled,
                      onChanged: (value) => _updateSetting(
                        (settings) =>
                            settings.copyWith(vibrationEnabled: value),
                        () => _vibrationEnabled = value,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _SettingsSwitchTile(
                      icon: Icons.auto_awesome_rounded,
                      title: '완료 이펙트',
                      subtitle: '퀘스트 완료 시 폭죽 효과 표시',
                      value: _celebrationEffectEnabled,
                      onChanged: (value) => _updateSetting(
                        (settings) =>
                            settings.copyWith(celebrationEffectEnabled: value),
                        () => _celebrationEffectEnabled = value,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _SettingsSwitchTile(
                      icon: Icons.save_outlined,
                      title: '자동 저장',
                      subtitle: '진행 상태를 자동으로 로컬에 저장',
                      value: _autoSaveEnabled,
                      onChanged: (value) => _updateSetting(
                        (settings) => settings.copyWith(autoSaveEnabled: value),
                        () => _autoSaveEnabled = value,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              RoundedCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    SectionHeading(
                      icon: Icons.timer_outlined,
                      title: '기본 퀘스트 시간',
                    ),
                    SizedBox(height: 16),
                    _SettingsInfoRow(label: '쉬움', value: '25분'),
                    SizedBox(height: 12),
                    _SettingsInfoRow(label: '보통', value: '45분'),
                    SizedBox(height: 12),
                    _SettingsInfoRow(label: '어려움', value: '90분'),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              RoundedCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    SectionHeading(
                      icon: Icons.info_outline_rounded,
                      title: '앱 정보',
                    ),
                    SizedBox(height: 16),
                    _SettingsInfoRow(label: '앱 버전', value: '1.0.0+1'),
                    SizedBox(height: 12),
                    _SettingsInfoRow(label: '테마', value: 'Light'),
                    SizedBox(height: 12),
                    _SettingsInfoRow(label: '저장 방식', value: 'Local Storage'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleNotionCalendarToggle(bool newValue) async {
    if (newValue) {
      final success = await _connectNotion();
      if (!mounted) {
        return;
      }
      setState(() => _isNotionSyncEnabled = success);
      return;
    }

    await _disconnectNotion();
    if (!mounted) {
      return;
    }
    setState(() => _isNotionSyncEnabled = false);
  }

  Future<void> _loadSettings() async {
    final settings = await _settingsStore.load();
    if (!mounted) {
      return;
    }

    setState(() {
      _notificationsEnabled = settings.notificationsEnabled;
      _vibrationEnabled = settings.vibrationEnabled;
      _celebrationEffectEnabled = settings.celebrationEffectEnabled;
      _autoSaveEnabled = settings.autoSaveEnabled;
      _isNotionSyncEnabled = settings.notionSyncEnabled;
      _notionDatabaseId = settings.notionDatabaseId;
      _notionDatabaseTitle = settings.notionDatabaseTitle;
      _notionApiTokenDraft = settings.notionApiToken;
      _notionDatabaseInputDraft = settings.notionDatabaseId;
    });
  }

  Future<bool> _connectNotion() async {
    if (!mounted) {
      return false;
    }
    final input = await showDialog<_NotionConnectionInput>(
      context: context,
      barrierDismissible: !_isNotionSyncBusy,
      builder: (_) => _NotionConnectDialog(
        initialApiToken: _notionApiTokenDraft,
        initialDatabaseInput: _notionDatabaseInputDraft,
        onDraftChanged: (draft) {
          _notionApiTokenDraft = draft.apiToken;
          _notionDatabaseInputDraft = draft.databaseInput;
        },
      ),
    );
    if (input == null) {
      return false;
    }

    _notionApiTokenDraft = input.apiToken;
    _notionDatabaseInputDraft = input.databaseInput;
    return _syncNotionTasks(input: input, enableSync: true);
  }

  Future<void> _disconnectNotion() async {
    final currentSettings = await _settingsStore.load();
    await _settingsStore.save(
      currentSettings.copyWith(
        notionSyncEnabled: false,
        notionApiToken: '',
        notionDatabaseId: '',
        notionDatabaseTitle: '',
      ),
    );

    final currentData = await _localDataStore.load();
    await _localDataStore.save(_localDataStore.removeNotionQuests(currentData));

    if (!mounted) {
      return;
    }
    setState(() {
      _notionDatabaseId = '';
      _notionDatabaseTitle = '';
      _notionApiTokenDraft = '';
      _notionDatabaseInputDraft = '';
    });
    _showMessage('Notion 연동을 해제하고 가져온 퀘스트를 정리했어요.');
  }

  Future<bool> _syncNotionTasks({
    _NotionConnectionInput? input,
    bool enableSync = false,
  }) async {
    final settings = await _settingsStore.load();
    final apiToken = (input?.apiToken ?? settings.notionApiToken).trim();
    final databaseInput = (input?.databaseInput ?? settings.notionDatabaseId)
        .trim();

    if (apiToken.isEmpty || databaseInput.isEmpty) {
      _showMessage('먼저 Notion integration secret과 데이터베이스 주소를 입력해 주세요.');
      return false;
    }

    if (!mounted) {
      return false;
    }
    setState(() => _isNotionSyncBusy = true);

    try {
      final result = await _notionSyncService.syncDatabase(
        NotionSyncConfig(apiToken: apiToken, databaseInput: databaseInput),
      );
      await _settingsStore.save(
        settings.copyWith(
          notionSyncEnabled: true,
          notionApiToken: apiToken,
          notionDatabaseId: result.databaseId,
          notionDatabaseTitle: result.databaseTitle,
        ),
      );

      final currentData = await _localDataStore.load();
      await _localDataStore.save(
        _localDataStore.replaceNotionQuests(currentData, result.quests),
      );

      if (!mounted) {
        return true;
      }

      setState(() {
        _isNotionSyncEnabled = true;
        _notionDatabaseId = result.databaseId;
        _notionDatabaseTitle = result.databaseTitle;
        _notionApiTokenDraft = apiToken;
        _notionDatabaseInputDraft = result.databaseId;
      });
      _showMessage(
        enableSync
            ? '${result.quests.length}개의 Notion 퀘스트를 연결했어요.'
            : '${result.quests.length}개의 Notion 퀘스트를 다시 가져왔어요.',
      );
      return true;
    } on NotionSyncException catch (error) {
      _showMessage(error.message);
      return false;
    } catch (_) {
      _showMessage('Notion 동기화 중 알 수 없는 오류가 발생했습니다.');
      return false;
    } finally {
      if (mounted) {
        setState(() => _isNotionSyncBusy = false);
      }
    }
  }

  Future<void> _updateNotificationsEnabled(bool value) async {
    var nextValue = value;
    if (value) {
      final status = await Permission.notification.request();
      nextValue = status.isGranted;
    }

    await _updateSetting(
      (settings) => settings.copyWith(notificationsEnabled: nextValue),
      () => _notificationsEnabled = nextValue,
    );

    if (!value || nextValue || !mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('알림 권한이 허용되지 않아 알림을 켤 수 없습니다.')),
    );
  }

  Future<void> _updateSetting(
    AppSettings Function(AppSettings current) transformer,
    VoidCallback applyState,
  ) async {
    final current = await _settingsStore.load();
    final next = transformer(current);
    await _settingsStore.save(next);
    if (!mounted) {
      return;
    }
    setState(applyState);
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  const _SettingsSwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBFF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEEF0),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFFFF8B93), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF33415C),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF7E899D),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeThumbColor: const Color(0xFFFF8B93),
            activeTrackColor: const Color(0xFFFFD2D7),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _SettingsActionTile extends StatelessWidget {
  const _SettingsActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFE1E6)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEEF0),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFFFF8B93), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF33415C),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF7E899D),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF8B93),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(buttonLabel),
          ),
        ],
      ),
    );
  }
}

class _SettingsInfoRow extends StatelessWidget {
  const _SettingsInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            color: Color(0xFF667085),
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            color: Color(0xFF33415C),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _NotionConnectionInput {
  const _NotionConnectionInput({
    required this.apiToken,
    required this.databaseInput,
  });

  final String apiToken;
  final String databaseInput;
}

class _NotionConnectDialog extends StatefulWidget {
  const _NotionConnectDialog({
    required this.initialApiToken,
    required this.initialDatabaseInput,
    required this.onDraftChanged,
  });

  final String initialApiToken;
  final String initialDatabaseInput;
  final ValueChanged<_NotionConnectionInput> onDraftChanged;

  @override
  State<_NotionConnectDialog> createState() => _NotionConnectDialogState();
}

class _NotionConnectDialogState extends State<_NotionConnectDialog> {
  late final TextEditingController _apiTokenController = TextEditingController(
    text: widget.initialApiToken,
  );
  late final TextEditingController _databaseController = TextEditingController(
    text: widget.initialDatabaseInput,
  );
  bool _obscureToken = true;

  @override
  void initState() {
    super.initState();
    _apiTokenController.addListener(_notifyDraftChanged);
    _databaseController.addListener(_notifyDraftChanged);
  }

  @override
  void dispose() {
    _apiTokenController.removeListener(_notifyDraftChanged);
    _databaseController.removeListener(_notifyDraftChanged);
    _apiTokenController.dispose();
    _databaseController.dispose();
    super.dispose();
  }

  void _notifyDraftChanged() {
    widget.onDraftChanged(
      _NotionConnectionInput(
        apiToken: _apiTokenController.text,
        databaseInput: _databaseController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Notion 연결'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notion integration secret과 data source ID(권장) 또는 원본 데이터베이스 URL/ID를 입력하세요.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _apiTokenController,
              obscureText: _obscureToken,
              decoration: InputDecoration(
                labelText: 'Integration Secret',
                hintText: 'ntn_xxx',
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() => _obscureToken = !_obscureToken);
                  },
                  icon: Icon(
                    _obscureToken
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _databaseController,
              decoration: const InputDecoration(
                labelText: 'Data source ID 또는 Database URL/ID',
                hintText: 'data source UUID 또는 https://www.notion.so/...',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop(
              _NotionConnectionInput(
                apiToken: _apiTokenController.text,
                databaseInput: _databaseController.text,
              ),
            );
          },
          child: const Text('연결'),
        ),
      ],
    );
  }
}
