package sample;

import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.Response;

import mdk.Functions;
import mdk.MDK;
import mdk.Session;
import mdk_discovery.Node;

public class ClientMain {

    public static void main(String[] args) throws java.io.IOException {
        MDK mdk = Functions.init();
        // Only need to create MDK once per process:
        mdk.start();
        try {
            while (true) {
                Session ssn = mdk.session();
                Node node = ssn.resolve(args[0], "1.0.0");
                String url = node.address;
                ssn.info("client", "Requesting from: " + url);
                Response r = request(url, ssn.inject());
                System.out.println(String.format("%s => %d: %s", url, r.code(), r.body().string()));
                sleep(1);
            }
        } finally {
            mdk.stop();
        }
    }

    private static Response request(String url, String mdk_context) throws java.io.IOException {
        OkHttpClient client = new OkHttpClient();
        Request request = new Request.Builder()
            .url(url)
            .header(MDK.CONTEXT_HEADER, mdk_context)
            .build();
        return client.newCall(request).execute();
    }

    private static void sleep(float duration) {
        try {
            Thread.sleep((int)(1000*duration));
        } catch (InterruptedException e) {
            ;
        }
    }
}
