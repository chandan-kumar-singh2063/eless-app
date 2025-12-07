import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:eless/extention/image_url_helper.dart';
import 'package:eless/model/cart_item.dart';
import 'package:eless/theme/app_theme.dart';

class CartCard extends StatelessWidget {
  final CartItem cartItem;

  const CartCard({super.key, required this.cartItem});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Device Image
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[200],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: cartItem.deviceImage.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: getFullImageUrl(cartItem.deviceImage),
                          fit: BoxFit.cover,
                          memCacheWidth: 200,
                          memCacheHeight: 200,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[300],
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.lightPrimaryColor,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[300],
                            child: Icon(
                              Icons.devices,
                              color: Colors.grey[500],
                              size: 28,
                            ),
                          ),
                        )
                      : Container(
                          color: Colors.grey[300],
                          child: Icon(
                            Icons.devices,
                            color: Colors.grey[500],
                            size: 28,
                          ),
                        ),
                ),
              ),

              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Device Name
                    Text(
                      cartItem.deviceName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),

                    // Admin Action Badge
                    _buildAdminActionBadge(),

                    const SizedBox(height: 8),

                    // Quantity Row
                    _buildQuantityRow(),

                    const SizedBox(height: 6),

                    // Status Row (show for approved, returned, or overdue items)
                    if (cartItem.isApproved ||
                        cartItem.isReturned ||
                        cartItem.isOverdueStatus) ...[
                      const SizedBox(height: 4),
                      _buildStatusRow(),
                    ],

                    const SizedBox(height: 6),

                    // Return Date (only show if available)
                    if (cartItem.returnDate.isNotEmpty)
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Return: ${_formatDate(cartItem.returnDate)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),

                    // Rejection Reason (only displayed if backend provides it - optional feature)
                    if (cartItem.isRejected &&
                        cartItem.rejectionReason != null &&
                        cartItem.rejectionReason!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.red[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 14,
                              color: Colors.red[700],
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                cartItem.rejectionReason!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.red[700],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminActionBadge() {
    Color badgeColor;
    Color textColor;
    String text;

    // Use overall_status or calculate from admin_action and status
    if (cartItem.isReturned) {
      badgeColor = Colors.green[100]!;
      textColor = Colors.green[800]!;
      text = 'Returned';
    } else if (cartItem.isOverdueStatus) {
      badgeColor = Colors.red[100]!;
      textColor = Colors.red[800]!;
      text = 'Overdue';
    } else if (cartItem.isPending) {
      badgeColor = Colors.orange[100]!;
      textColor = Colors.orange[800]!;
      text = 'Pending';
    } else if (cartItem.isApproved) {
      badgeColor = Colors.green[100]!;
      textColor = Colors.green[800]!;
      text = 'Approved';
    } else if (cartItem.isRejected) {
      badgeColor = Colors.red[100]!;
      textColor = Colors.red[800]!;
      text = 'Rejected';
    } else {
      // Fallback - should not happen
      badgeColor = Colors.grey[100]!;
      textColor = Colors.grey[800]!;
      text = cartItem.displayStatus;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildQuantityRow() {
    if (cartItem.isApproved) {
      return Row(
        children: [
          Icon(Icons.check_circle_outline, size: 14, color: Colors.green[700]),
          const SizedBox(width: 4),
          Text(
            'Approved Qty: ${cartItem.approvedQuantity}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[800],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    } else {
      return Row(
        children: [
          Icon(Icons.shopping_cart_outlined, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            'Requested Qty: ${cartItem.requestedQuantity}',
            style: TextStyle(fontSize: 12, color: Colors.grey[800]),
          ),
        ],
      );
    }
  }

  Widget _buildStatusRow() {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (cartItem.isOverdueStatus) {
      // Overdue takes priority
      statusColor = Colors.red[700]!;
      statusIcon = Icons.warning;
      statusText = 'Overdue';
    } else if (cartItem.isReturned) {
      // Returned
      statusColor = Colors.green[700]!;
      statusIcon = Icons.check_circle;
      statusText = 'Returned';
    } else if (cartItem.isOnService) {
      // On Service (approved and not returned/overdue)
      statusColor = Colors.blue[700]!;
      statusIcon = Icons.schedule;
      statusText = 'On Service';
    } else {
      // Fallback - use display status from backend
      statusColor = Colors.grey[700]!;
      statusIcon = Icons.info_outline;
      statusText = cartItem.displayStatus;
    }

    return Row(
      children: [
        Icon(statusIcon, size: 14, color: statusColor),
        const SizedBox(width: 4),
        Text(
          statusText,
          style: TextStyle(
            fontSize: 12,
            color: statusColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }
}
