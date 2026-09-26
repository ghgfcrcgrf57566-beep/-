                    child: Text(
                      _pages == null
                          ? 'جاري تحميل الصفحات...'
                          : 'صفحة ${_page + 1} من ${_pages}',
                      style: const TextStyle(
                        color: _goldLight,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),