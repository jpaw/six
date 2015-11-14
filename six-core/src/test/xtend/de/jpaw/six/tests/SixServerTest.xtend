package de.jpaw.six.tests

import de.jpaw.six.server.SixServer
import io.vertx.core.Vertx
import static io.vertx.core.http.HttpHeaders.*
import io.vertx.ext.unit.TestContext
import io.vertx.ext.unit.junit.VertxUnitRunner
import org.junit.After
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import java.nio.charset.StandardCharsets
import java.util.Base64
import de.jpaw.six.demo.DummyAuthenticationBackend

@RunWith(VertxUnitRunner)
public class JwtRemoteTest {
    private static final String RPC_PATH = "/api/rpc"

    private Vertx vertx;

    @Before
    def public void setUp(TestContext context) {
        SixServer.initializeJdp
        vertx = Vertx.vertx()
        vertx.deployVerticle(SixServer.name, context.asyncAssertSuccess)
    }

    @After
    def public void tearDown(TestContext context) {
        vertx.close(context.asyncAssertSuccess)
    }

    @Test
    def public void testSixServer(TestContext context) {
        val async = context.async

        vertx.createHttpClient => [
            getNow(8080, "localhost", "/auth/login", [
                if (statusCode != 200) {
                    println('''Result: error code «statusCode», msg «statusMessage»''')
                    async.complete
                } else {
                    handler [
                        println('''Result: token = «it»''')
                        async.complete
                    ]
                }
            ])  
        ]
    }
    
    @Test
    def public void testSixServerBasicAuth(TestContext context) {
        val async = context.async
        
        val authHdr = Base64.urlEncoder.encode("john:secret".getBytes(StandardCharsets.UTF_8))

        vertx.createHttpClient => [
            get(8080, "localhost", "/api/demo/hello", [
                if (statusCode != 200) {
                    println('''Result: error code «statusCode», msg «statusMessage»''')
                    async.complete
                } else {
                    handler [
                        println('''Result: token = «it»''')
                        async.complete
                    ]
                }
            ])
            .putHeader(AUTHORIZATION, "Basic " + new String(authHdr, StandardCharsets.UTF_8))
            .end
        ]
    }

    @Test
    def public void testSixServerBasicAuthRpc(TestContext context) {
        val async = context.async
        
        val authHdr = Base64.urlEncoder.encode("john:secret".getBytes(StandardCharsets.UTF_8))

        vertx.createHttpClient => [
            post(8080, "localhost", "/api/rpc", [
                if (statusCode != 200) {
                    println('''Result: error code «statusCode», msg «statusMessage»''')
                    async.complete
                } else {
                    handler [
                        println('''Result: token = «it»''')
                        async.complete
                    ]
                }
            ])
            .putHeader(AUTHORIZATION, "Basic " + new String(authHdr, StandardCharsets.UTF_8))
            .putHeader(CONTENT_TYPE, "application/json")
            .end('''{  "foo": "bar", "decision": true, "list": [ 1, 2, 3, 4, 3.14 ] }''')
        ]
    }

    @Test
    def public void testSixServerApiKey(TestContext context) {
        val async = context.async
        
        val authHdr = DummyAuthenticationBackend.DEMO_API_KEY

        vertx.createHttpClient => [
            get(8080, "localhost", "/api/demo/hello", [
                if (statusCode != 200) {
                    println('''Result: error code «statusCode», msg «statusMessage»''')
                    async.complete
                } else {
                    handler [
                        println('''Result: token = «it»''')
                        async.complete
                    ]
                }
            ])
            .putHeader(AUTHORIZATION, "API-Key " + authHdr)
            .end
        ]
    }

    @Test
    def public void testSixServerNoAuth(TestContext context) {
        val async = context.async

        vertx.createHttpClient => [
            post(8080, "localhost", RPC_PATH, [
                println('''returns «statusCode» with msg «statusMessage»''')
                if (statusCode == 200)
                    endHandler [ 
                        println('''Result: token = «it»''')
                        async.complete
                    ]
                else
                    async.complete
            ])
            .end  
        ]
    }
    
    @Test
    def public void testSixServerBadAuth(TestContext context) {
        val async = context.async

        vertx.createHttpClient => [
            post(8080, "localhost", RPC_PATH, [
                println('''returns «statusCode» with msg «statusMessage»''')
                if (statusCode == 200)
                    endHandler [ 
                        println('''Result: token = «it»''')
                        async.complete
                    ]
                else
                    async.complete
            ])
            .putHeader(AUTHORIZATION, "ghghghgh.ggg.ggg")
            .end  
        ]
    }
    
    @Test
    def public void testSixServerBadAuth2(TestContext context) {
        val async = context.async

        vertx.createHttpClient => [
            post(8080, "localhost", RPC_PATH, [
                println('''returns «statusCode» with msg «statusMessage»''')
                if (statusCode == 200)
                    endHandler [ 
                        println('''Result: token = «it»''')
                        async.complete
                    ]
                else
                    async.complete
            ])
            .putHeader(AUTHORIZATION, "Bearer ghghghgh.ggg.ggg")
            .end  
        ]
    }
    
    @Test
    def public void testSixServerGoodAuth(TestContext context) {
        val async = context.async

        val clt = vertx.createHttpClient
        clt.getNow(8080, "localhost", "/auth/login", [
            handler [
                val jwt = toString
                clt.post(8080, "localhost", RPC_PATH, [
                    println('''returns «statusCode» with msg «statusMessage»''')
                    if (statusCode == 200)
                        bodyHandler [ 
                            println('''Result: token = «it»''')
                            async.complete
                        ]
                    else
                        async.complete
                ])
                .putHeader(AUTHORIZATION, "Bearer " + jwt)
                .putHeader(CONTENT_TYPE, "application/json")
                .end('''{
                    "foo": "bar"
                }
                ''')  
            ]
        ])
    }
}
