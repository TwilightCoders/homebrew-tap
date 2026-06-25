class Progresql < Formula
  desc "PostgreSQL 18 fork adding cross-partition GLOBAL UNIQUE/PK (spanning) indexes"
  homepage "https://github.com/TwilightCoders/progresql"
  url "https://github.com/TwilightCoders/progresql/archive/refs/tags/v18.3-0.2.3.tar.gz"
  sha256 "fc85ce8fad9ca8a83b411e54f2e6dfc6be479eaaa175e643e8a86f8b0c23ee81"
  license "PostgreSQL"
  head "https://github.com/TwilightCoders/progresql.git", branch: "progresql-c1"

  # ProgreSQL ships the same binaries (postgres, psql, pg_ctl, initdb, ...) as
  # stock PostgreSQL and is an experimental (Beta) fork.  Keep it keg-only so it
  # never shadows a real PostgreSQL install or a pg_cluster/petere setup; invoke
  # it via the full keg path (or add #{HOMEBREW_PREFIX}/opt/progresql/bin to PATH
  # deliberately).
  keg_only "it is an experimental fork that provides the same binaries as postgresql"

  depends_on "bison" => :build   # macOS's bundled bison is too old for the PG grammar
  depends_on "flex" => :build    # likewise for the scanner
  depends_on "pkgconf" => :build
  depends_on "openssl@3"
  depends_on "readline"

  uses_from_macos "zlib"

  def install
    # The release tarball is a git archive (no pre-generated parser/scanner),
    # so a fresh bison/flex must be on PATH ahead of the macOS ones.
    ENV.prepend_path "PATH", Formula["bison"].opt_bin
    ENV.prepend_path "PATH", Formula["flex"].opt_bin

    args = %W[
      --prefix=#{prefix}
      --with-openssl
      --with-readline
      --without-icu
      --with-includes=#{Formula["openssl@3"].opt_include}:#{Formula["readline"].opt_include}
      --with-libraries=#{Formula["openssl@3"].opt_lib}:#{Formula["readline"].opt_lib}
    ]

    system "./configure", *args
    system "make"
    system "make", "install"
    # Build + install the full contrib module set, for drop-in parity with a stock
    # PostgreSQL distribution: amcheck (the spanning-index oracle, also used by the
    # test block below), citext, pgcrypto, hstore, pg_trgm, btree_gin/gist, and the
    # rest. contrib's own Makefile skips modules gated on deps this lean configure
    # does not enable (uuid-ossp, sepgsql, the PL transforms).
    system "make", "-C", "contrib"
    system "make", "-C", "contrib", "install"
  end

  test do
    datadir = testpath/"data"
    system bin/"initdb", "--auth=trust", "--locale=C", "--encoding=UTF8", "-D", datadir
    port = free_port
    system bin/"pg_ctl", "-D", datadir, "-l", testpath/"log",
           "-o", "-c listen_addresses='' -k #{testpath} -p #{port}", "-w", "start"
    begin
      # The whole point of the fork: a GLOBAL (spanning) primary key enforces
      # uniqueness across partitions.  Build one, then prove a same-key insert
      # into a different partition is rejected.
      setup = <<~SQL
        CREATE TABLE s (id int NOT NULL, p int NOT NULL,
            PRIMARY KEY (id) GLOBAL) PARTITION BY LIST (p);
        CREATE TABLE s0 PARTITION OF s FOR VALUES IN (0);
        CREATE TABLE s1 PARTITION OF s FOR VALUES IN (1);
        INSERT INTO s VALUES (1, 0);
      SQL
      system bin/"psql", "-h", testpath, "-p", port.to_s, "-d", "postgres",
             "-v", "ON_ERROR_STOP=1", "-c", setup
      dup = shell_output(
        "#{bin}/psql -h #{testpath} -p #{port} -d postgres " \
        "-c \"INSERT INTO s VALUES (1, 1)\" 2>&1", 1
      )
      assert_match "duplicate key value violates unique constraint", dup
    ensure
      system bin/"pg_ctl", "-D", datadir, "stop"
    end
  end
end
