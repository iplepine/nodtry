part of '../us_screen.dart';

class _EditProfileDialogContent extends ConsumerStatefulWidget {
  final String name;
  final String? status;
  final String? imageUrl;
  final AppLocalizations l10n;
  final WidgetRef ref;

  const _EditProfileDialogContent({
    required this.name,
    this.status,
    this.imageUrl,
    required this.l10n,
    required this.ref,
  });

  @override
  ConsumerState<_EditProfileDialogContent> createState() =>
      _EditProfileDialogContentState();
}

class _EditProfileDialogContentState
    extends ConsumerState<_EditProfileDialogContent> {
  late TextEditingController _nameController;
  late TextEditingController _statusController;
  File? _tempProfileImage;
  bool _isSaving = false;
  String? _nameError;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _statusController = TextEditingController(text: widget.status);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _statusController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      // 2. 이미지 선택
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        final croppedFile = await ImageCropper().cropImage(
          sourcePath: pickedFile.path,

          maxWidth: 512,
          maxHeight: 512,

          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: widget.l10n.usCropImageTitle,
              toolbarColor: AppColors.primary,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: true,
            ),
            IOSUiSettings(
              title: widget.l10n.usCropImageTitle,
              aspectRatioLockEnabled: true,
              resetAspectRatioEnabled: false,
            ),
          ],
        );

        if (croppedFile != null) {
          setState(() {
            _tempProfileImage = File(croppedFile.path);
          });
        }
      }
    } catch (e, stack) {
      // A permission denial or a cropper failure used to leave the user tapping
      // the camera badge with nothing happening at all.
      ErrorReporter.record(e, stack, reason: 'pickProfileImage');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(widget.l10n.usImagePickFailed)));
      }
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    // An empty name saved fine and your own view masked it with a fallback, but
    // partner-facing views null-coalesce — they showed a blank name and a
    // "Disconnect from ?" dialog.
    if (name.isEmpty) {
      setState(() => _nameError = widget.l10n.usNameRequired);
      return;
    }
    setState(() {
      _nameError = null;
      _isSaving = true;
    });

    try {
      final updateUseCase = ref.read(updateProfileUseCaseProvider);
      await updateUseCase.execute(
        name: name,
        statusMessage: _statusController.text.isEmpty
            ? null
            : _statusController.text,
        imagePath: _tempProfileImage?.path,
      );

      // Provider 새로고침 (Stream으로 자동 갱신되므로 불필요)
      // ref.invalidate(myProfileProvider);

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e, stack) {
      ErrorReporter.record(e, stack, reason: 'saveProfile');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.l10n.usProfileSaveFailed)),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      backgroundColor: AppColors.surface,
      title: Text(
        widget.l10n.usEditProfile,
        style: TextStyle(color: AppColors.textPrimary),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 프로필 사진 편집
          Semantics(
            label: widget.l10n.usProfileEditImageLabel,
            button: true,
            child: GestureDetector(
              onTap: _isSaving ? null : _pickImage,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  if (_tempProfileImage != null)
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: FileImage(_tempProfileImage!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  else if (widget.imageUrl != null &&
                      widget.imageUrl!.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: widget.imageUrl!,
                      imageBuilder: (context, imageProvider) => Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            image: imageProvider,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      placeholder: (context, url) => Shimmer.fromColors(
                        baseColor: AppColors.surface,
                        highlightColor: Colors.white,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.person,
                          size: 48,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person,
                        size: 48,
                        color: AppColors.primary,
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.surface, width: 2),
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // 이름 입력
          TextField(
            controller: _nameController,
            enabled: !_isSaving,
            maxLength: 20,
            onChanged: (_) {
              if (_nameError != null) setState(() => _nameError = null);
            },
            decoration: InputDecoration(
              labelText: widget.l10n.usNameLabel,
              labelStyle: TextStyle(color: AppColors.textSecondary),
              errorText: _nameError,
              counterText: '',
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.divider),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.primary),
              ),
            ),
            style: TextStyle(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 16),
          // 상태 메시지 입력
          TextField(
            controller: _statusController,
            enabled: !_isSaving,
            decoration: InputDecoration(
              labelText: widget.l10n.usStatusLabel,
              labelStyle: TextStyle(color: AppColors.textSecondary),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.divider),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.primary),
              ),
            ),
            style: TextStyle(color: AppColors.textPrimary),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: Text(
            widget.l10n.usCancel,
            style: TextStyle(
              color: _isSaving
                  ? AppColors.textDisabled
                  : AppColors.textSecondary,
            ),
          ),
        ),
        if (_isSaving)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else
          TextButton(
            onPressed: _save,
            child: Text(
              widget.l10n.usSave,
              style: TextStyle(color: AppColors.primary),
            ),
          ),
      ],
    );
  }
}
