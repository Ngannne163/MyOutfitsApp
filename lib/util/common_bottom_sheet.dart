import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../data/model/comment_model.dart';
import '../data/view_model/comment_view_model.dart';


const String DEFAULT_NETWORK_AVATAR_URL =
    'https://firebasestorage.googleapis.com/v0/b/myoutfits-937e9.firebaseapp.app/o/person.png?alt=media&token=2f4a0a4f-ecc3-4599-b9a9-0eabba28ca308';

class CommentBottomSheet extends StatefulWidget {
  final String postId;
  final Function(int) onCommentCountUpdated;

  const CommentBottomSheet({
    super.key,
    required this.postId,
    required this.onCommentCountUpdated,
  });

  @override
  State<CommentBottomSheet> createState() => _CommentBottomSheetState();
}

class _CommentBottomSheetState extends State<CommentBottomSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = Provider.of<CommentViewModel>(context, listen: false);
      viewModel.addListener(_updateHostCommentCount);
    });
  }

  void _updateHostCommentCount() {
    final viewModel = Provider.of<CommentViewModel>(context, listen: false);
    widget.onCommentCountUpdated(viewModel.comments.length);
  }

  @override
  void dispose() {
    Provider.of<CommentViewModel>(context, listen: false).removeListener(_updateHostCommentCount);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.viewInsets.bottom;

    return Container(
      height: mediaQuery.size.height * 0.8 + bottomPadding,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // 1. Header (Thanh kéo và tiêu đề)
          _buildHeader(context),

          // 2. Danh sách Comments
          Expanded(child: _buildCommentList()),

          // 3. Khung nhập liệu (Input Box)
          _buildCommentInput(),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    // Sử dụng Consumer để lắng nghe số lượng comment real-time
    return Consumer<CommentViewModel>(
      builder: (context, viewModel, child) {
        final commentCount = viewModel.comments.length;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Bình luận (${commentCount})',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Divider(height: 1, thickness: 0.5, color: Colors.grey),
          ],
        );
      },
    );
  }

  Widget _buildCommentList() {
    return Consumer<CommentViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.errorMessage != null) {
          return Center(child: Text('Lỗi: ${viewModel.errorMessage}'));
        }
        if (viewModel.comments.isEmpty) {
          return const Center(child: Text("Hãy là người đầu tiên bình luận!"));
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: 10, bottom: 10),
          itemCount: viewModel.comments.length,
          itemBuilder: (context, index) {
            final comment = viewModel.comments[index];
            return CommentItem(comment: comment);
          },
        );
      },
    );
  }

  Widget _buildCommentInput() {
    return CommentInputBox(
      viewModel: Provider.of<CommentViewModel>(context, listen: false),
    );
  }
}



class CommentItem extends StatelessWidget {
  final CommentModel comment;
  const CommentItem({super.key, required this.comment});

  Widget _buildAvatar(String? url) {
    String finalUrl = (url != null && url.isNotEmpty) ? url : DEFAULT_NETWORK_AVATAR_URL;

    return SizedBox(
      width: 36,
      height: 36,
      child: AvatarWithFallback(
        userProfileUrl: url,
        defaultUrl: DEFAULT_NETWORK_AVATAR_URL,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    timeago.setLocaleMessages('vi', timeago.ViMessages());
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAvatar(comment.userProfileUrl),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.username,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      comment.timestamp.toDate() != null
                          ? timeago.format(comment.timestamp.toDate(), locale: 'vi')
                          : 'Vừa xong',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  comment.content,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- Component Input Box ---
class CommentInputBox extends StatefulWidget {
  final CommentViewModel viewModel;
  const CommentInputBox({super.key, required this.viewModel});

  @override
  State<CommentInputBox> createState() => _CommentInputBoxState();
}

class _CommentInputBoxState extends State<CommentInputBox> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Bắt buộc thêm listener để cập nhật trạng thái icon gửi
    _controller.addListener(() => setState(() {}));
  }

  void _sendComment() {
    if (_controller.text.isNotEmpty) {
      widget.viewModel.postComment(_controller.text.trim());
      _controller.clear();
      FocusScope.of(context).unfocus();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(() => setState(() {}));
    _controller.dispose();
    super.dispose();
  }

  Widget _buildCurrentUserAvatar(String? url) {
    return SizedBox(
      width: 36,
      height: 36,
      child: AvatarWithFallback(
        userProfileUrl: url,
        defaultUrl: DEFAULT_NETWORK_AVATAR_URL,
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final viewModel = widget.viewModel;
    final String? currentUserProfileUrl = viewModel.currentUserProfileUrl;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 8, 8, MediaQuery.of(context).padding.bottom + 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(top: BorderSide(color: Colors.grey.shade300, width: 0.5)),
      ),
      child: Row(
        children: [
          _buildCurrentUserAvatar(currentUserProfileUrl),
          const SizedBox(width: 10),

          // Input Field
          Expanded(
            child: TextField(
              controller: _controller,
              autocorrect: false,
              enableSuggestions: false,
              decoration: const InputDecoration(
                hintText: "Bạn nghĩ gì về nội dung này?",
                border: InputBorder.none,
                isDense: true,
              ),
              enabled: !viewModel.isPosting,
            ),
          ),

          // Nút Gửi / Loading
          if (viewModel.isPosting)
            const Padding(
              padding: EdgeInsets.only(left: 8.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            )
          else
            IconButton(
              icon: Icon(
                Icons.send,
                // Màu xanh nếu có nội dung, màu xám nếu rỗng
                color: _controller.text.trim().isNotEmpty ? Colors.blue : Colors.grey,
              ),
              onPressed: _controller.text.trim().isNotEmpty ? _sendComment : null,
            ),
        ],
      ),
    );
  }
}
class AvatarWithFallback extends StatefulWidget {
  final String? userProfileUrl;
  final String defaultUrl;

  const AvatarWithFallback({
    super.key,
    required this.userProfileUrl,
    required this.defaultUrl,
  });

  @override
  State<AvatarWithFallback> createState() => _AvatarWithFallbackState();
}

class _AvatarWithFallbackState extends State<AvatarWithFallback> {
  late String _currentUrl;

  @override
  void initState() {
    super.initState();
    _initializeUrl(widget.userProfileUrl);
  }

  @override
  void didUpdateWidget(covariant AvatarWithFallback oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.userProfileUrl != oldWidget.userProfileUrl) {
      _initializeUrl(widget.userProfileUrl);
    }
  }

  void _initializeUrl(String? url) {
    // Ưu tiên ảnh user, nếu không có/rỗng thì dùng ảnh mặc định
    _currentUrl = (url != null && url.isNotEmpty)
        ? url
        : widget.defaultUrl;
  }

  void _handleImageError(Object exception, StackTrace? stackTrace) {
    if (_currentUrl == widget.userProfileUrl && _currentUrl != widget.defaultUrl && mounted) {
      setState(() {
        _currentUrl = widget.defaultUrl;
      });
    } else if (mounted) {
    }
  }

  @override
  Widget build(BuildContext context) {

    final Key imageKey = ValueKey(_currentUrl);
    final ImageProvider imageProvider = NetworkImage(_currentUrl);

    return CircleAvatar(
      key: imageKey,
      radius: 18,
      backgroundImage: imageProvider,
      backgroundColor: Colors.grey.shade200,

      child: Image(
        key: imageKey,
        image: imageProvider,
        fit: BoxFit.cover,
        width: 36,
        height: 36,
        errorBuilder: (context, error, stackTrace) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _handleImageError(error, stackTrace);
          });
          return const Center(child: Icon(Icons.person, size: 20, color: Colors.grey));
        },
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (frame != null || wasSynchronouslyLoaded) {
            return const SizedBox.shrink();
          }
          return const Center(child: Icon(Icons.person, size: 20, color: Colors.grey));
        },
      ),
    );
  }
}
