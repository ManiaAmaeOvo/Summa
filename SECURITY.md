# Security Policy

**English** | [简体中文](SECURITY.zh-CN.md)

Summa handles highly sensitive personal financial data. Never attach a real
backup, database, transaction screenshot, signing key, or identifying
information to a public issue.

Use GitHub's private vulnerability reporting feature for security issues. If it
is unavailable, contact the maintainer through
[ManiaAmaeOvo](https://github.com/ManiaAmaeOvo). Reports should use synthetic
test data.

The current early release does not encrypt its SQLite database. Device unlock
protection, the Android application sandbox, and careful handling of exported
backup files are the present security boundary.
