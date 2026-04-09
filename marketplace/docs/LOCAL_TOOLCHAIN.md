# Local Toolchain Setup (macOS)

## Required versions

- Ruby 3.2+
- Bundler 2.5+
- PostgreSQL 14+
- Redis 7+
- Node 20+

## Suggested install

```bash
brew install rbenv ruby-build postgresql@16 redis node@20
rbenv install 3.2.2
rbenv local 3.2.2
gem install bundler -v '~> 2.5'
```

Start dependencies:

```bash
brew services start postgresql@16
brew services start redis
```
