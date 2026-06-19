// File: lib/pages/news/comments_page.dart
// HALAMAN FULL COMMENTS dengan list semua comments dan input box

import 'package:flutter/material.dart';
import 'package:ayotani/theme/app_colors.dart';
import '../../models/comment_model.dart';

class CommentsPage extends StatefulWidget {
  final List<Comment> comments;
  final int commentCount;

  CommentsPage({
    Key? key,
    required this.comments,
    required this.commentCount,
  }) : super(key: key);

  @override
  State<CommentsPage> createState() => _CommentsPageState();
}

class _CommentsPageState extends State<CommentsPage> {
  final TextEditingController _commentController = TextEditingController();
  late List<Comment> _comments;

  @override
  void initState() {
    super.initState();
    _comments = List.from(widget.comments);
  }

  void _sendComment() {
    if (_commentController.text.trim().isNotEmpty) {
      setState(() {
        _comments.add(
          Comment(
            id: _comments.length + 1,
            author: "You",
            time: "Just now",
            text: _commentController.text,
            likes: 0,
            replies: [],
          ),
        );
        _commentController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.scaffoldBg,
        elevation: 1,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Comments',
          style: TextStyle(
            color: context.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildCommentsHeader(),
          _buildCommentsList(),
          _buildCommentInput(),
        ],
      ),
    );
  }

  Widget _buildCommentsHeader() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${_comments.length} Comments',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          Row(
            children: [
              Text(
                'All Comments',
                style: TextStyle(color: context.textSecondary, fontSize: 14),
              ),
              Icon(Icons.keyboard_arrow_down, color: context.textSecondary, size: 20),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsList() {
    return Expanded(
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 16),
        itemCount: _comments.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(bottom: 20),
            child: _buildCommentWithReplies(_comments[index]),
          );
        },
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      decoration: BoxDecoration(
        color: context.cardBg,
        border: Border(top: BorderSide(color: context.dividerColor)),
      ),
      padding: EdgeInsets.all(16),
      child: SafeArea(
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: context.dividerColor,
              child: Icon(Icons.person, color: context.textSecondary, size: 24),
            ),
            SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _commentController,
                decoration: InputDecoration(
                  hintText: 'Type message',
                  hintStyle: TextStyle(color: context.textMuted),
                  filled: true,
                  fillColor: context.dividerColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                onSubmitted: (_) => _sendComment(),
              ),
            ),
            SizedBox(width: 12),
            IconButton(
              onPressed: _sendComment,
              icon: Icon(Icons.send, color: Colors.blue),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentWithReplies(Comment comment) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCommentItem(comment, false),
        if (comment.replies.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(left: 48, top: 12),
            child: Column(
              children: comment.replies
                  .map((reply) => Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: _buildCommentItem(reply, true),
                      ))
                  .toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildCommentItem(Comment comment, bool isReply) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: isReply ? 16 : 20,
          backgroundColor: context.dividerColor,
          child: Icon(
            Icons.person,
            color: context.textSecondary,
            size: isReply ? 18 : 24,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    comment.author,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    comment.time,
                    style: TextStyle(
                      color: context.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6),
              Text(
                comment.text,
                style: TextStyle(
                  fontSize: 14,
                  color: context.textPrimary,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.thumb_up_outlined, size: 14, color: context.textSecondary),
                  SizedBox(width: 4),
                  Text(
                    '${comment.likes}',
                    style: TextStyle(fontSize: 12, color: context.textSecondary),
                  ),
                  SizedBox(width: 16),
                  Text(
                    'Reply',
                    style: TextStyle(fontSize: 12, color: context.textSecondary),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}