package ph.mealpal.server.db;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.List;
import java.util.UUID;
import java.util.stream.Stream;
import javax.sql.DataSource;
import org.postgresql.ds.PGSimpleDataSource;

/**
 * A throwaway database built from supabase/migrations, so the store tests run against the schema
 * Supabase runs. MEALPAL_TEST_DATABASE_URL is a JDBC URL to a Postgres where the tests may create
 * and drop databases; `./gradlew postgresTest` needs it, and CI starts one.
 */
public final class TestDatabase implements AutoCloseable {

    static final Path MIGRATIONS = Path.of("supabase/migrations");

    private final String adminUrl;
    private final String name;
    private final PGSimpleDataSource dataSource;

    private TestDatabase(String adminUrl, String name, PGSimpleDataSource dataSource) {
        this.adminUrl = adminUrl;
        this.name = name;
        this.dataSource = dataSource;
    }

    public static TestDatabase create() throws SQLException, IOException {
        String adminUrl = System.getenv("MEALPAL_TEST_DATABASE_URL");
        if (adminUrl == null || adminUrl.isBlank()) {
            throw new IllegalStateException("Set MEALPAL_TEST_DATABASE_URL to a JDBC URL of a Postgres the tests "
                    + "may create databases in, e.g. jdbc:postgresql://127.0.0.1:5432/postgres?user=postgres");
        }
        String name = "mealpal_test_" + UUID.randomUUID().toString().replace("-", "").substring(0, 12);
        try (Connection admin = DriverManager.getConnection(adminUrl); Statement s = admin.createStatement()) {
            s.execute("create database " + name);
        }
        PGSimpleDataSource dataSource = new PGSimpleDataSource();
        dataSource.setURL(withDatabase(adminUrl, name));
        TestDatabase db = new TestDatabase(adminUrl, name, dataSource);
        db.migrate();
        return db;
    }

    /** The admin URL with its database swapped for [database]. */
    static String withDatabase(String url, String database) {
        return url.replaceFirst("^(jdbc:postgresql://[^/?]+)/[^?]*", "$1/" + database);
    }

    private void migrate() throws SQLException, IOException {
        List<Path> files;
        try (Stream<Path> listed = Files.list(MIGRATIONS)) {
            files = listed.filter(p -> p.toString().endsWith(".sql")).sorted().toList();
        }
        try (Connection c = dataSource.getConnection(); Statement s = c.createStatement()) {
            for (Path file : files) {
                s.execute(Files.readString(file));
            }
        }
    }

    public DataSource dataSource() {
        return dataSource;
    }

    @Override
    public void close() throws SQLException {
        try (Connection admin = DriverManager.getConnection(adminUrl); Statement s = admin.createStatement()) {
            s.execute("drop database if exists " + name + " with (force)");
        }
    }
}
