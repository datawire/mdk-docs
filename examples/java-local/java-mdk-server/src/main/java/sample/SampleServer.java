package sample;


import static spark.Spark.*;
import mdk.MDK;
import mdk.Session;
import mdk.Functions;

public class SampleServer {

    public static void main(String[] args) {
        String host = "127.0.0.1";
        int port = 5000;
        if (args.length > 1)
            port = Integer.valueOf(args[1]);

        // Only need to start MDK once per process:
        MDK mdk = Functions.init();
        mdk.start();
        Runtime.getRuntime().addShutdownHook(new Thread(() -> mdk.stop()));
        mdk.register(args[0], "1.0.0", String.format("http://%s:%d", host, port));

        spark.Spark.ipAddress(host);
        port(port);
        get("/", (req, res) -> {
                Session ssn = mdk.join(req.headers("X-MDK-Context"));
                ssn.info("server", "Got a request.");
                return "Hello World!\r\n";
            });
    }
}
