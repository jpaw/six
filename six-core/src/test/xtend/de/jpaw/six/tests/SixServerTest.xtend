package de.jpaw.six.tests

import de.jpaw.six.server.SixServer
import io.vertx.core.Vertx
import io.vertx.core.http.HttpHeaders
import io.vertx.ext.unit.TestContext
import io.vertx.ext.unit.junit.VertxUnitRunner
import org.junit.After
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith

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
                handler [
                    println('''Result: token = «it»''')
                    async.complete
                ]
            ])  
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
            .putHeader(HttpHeaders.AUTHORIZATION, "ghghghgh.ggg.ggg")
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
            .putHeader(HttpHeaders.AUTHORIZATION, "Bearer ghghghgh.ggg.ggg")
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
                .putHeader(HttpHeaders.AUTHORIZATION, "Bearer " + jwt)
                .putHeader(HttpHeaders.CONTENT_TYPE, "application/json")
                .end('''{
                    "foo": "bar"
                }
                ''')  
            ]
        ])
    }
}
