# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Security

- Upgrade `hono` to 4.12.9 (fixes arbitrary file access via `serveStatic` and 2 medium CVEs; required ≥4.12.4)
- Upgrade `@hono/node-server` to 1.19.12 (fixes auth bypass via encoded slashes; required ≥1.19.10)
- Upgrade `express-rate-limit` to 8.3.2 (fixes IPv4-mapped IPv6 bypass; required ≥8.2.2)
- Upgrade `path-to-regexp` to 8.4.1 (fixes ReDoS via sequential optional groups; required ≥8.4.0)
