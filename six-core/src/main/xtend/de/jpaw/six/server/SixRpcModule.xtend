package de.jpaw.six.server

import de.jpaw.bonaparte.core.BonaPortable
import de.jpaw.bonaparte.core.MessageParserException
import de.jpaw.bonaparte.core.StaticMeta
import de.jpaw.bonaparte.pojos.api.auth.JwtInfo
import de.jpaw.bonaparte8.vertx3.IMessageCoderFactory
import de.jpaw.dp.Dependent
import de.jpaw.dp.Inject
import de.jpaw.dp.Named
import de.jpaw.six.IServiceModule
import io.vertx.core.Vertx
import io.vertx.core.buffer.Buffer
import io.vertx.ext.web.Router
import org.slf4j.Logger
import org.slf4j.LoggerFactory

import static io.vertx.core.http.HttpHeaders.*

/** This is a pseudo module in the sense that rather than contributing a specific set of methods,
 * it provides a dispatcher.
 */
 @Named("rpc")
 @Dependent
class RpcModule implements IServiceModule {
    private static final Logger LOGGER = LoggerFactory.getLogger(SixServer)
    
    @Inject private IMessageCoderFactory<BonaPortable, byte[]> coderFactory
    
    override getExceptionOffset() {
        return 10_000
    }
    
    override getModuleName() {
        return "rpc"
    }
    
    override createRouter(Vertx vertx) {
        LOGGER.info("Registering module {}", moduleName)
        return Router.router(vertx) => [
            post.handler [
                LOGGER.info('''POST /rpc received...''')
                val start = System.currentTimeMillis
        
                val info = user?.principal?.map?.get("info")
                if (info === null || !(info instanceof JwtInfo)) {
                    throw new RuntimeException("No user defined or of bad type: Missing auth handler?") 
                }
                val info2 = info as JwtInfo
                val ct = request.headers.get(CONTENT_TYPE)
                if (ct === null) {
                    response.statusMessage = '''Undefined Content-Type'''
                    error = 415
                    return
                }
                // decode the payload
                val decoder = coderFactory.getDecoderInstance(ct)
                val encoder = coderFactory.getEncoderInstance(ct)
                if (decoder === null || encoder === null) {
                    response.statusMessage = '''Content-Type «ct» not supported for path /rpc'''
                    error = 415
                    return
                }
                vertx.executeBlocking([], [])
                var BonaPortable request
                try {
                    request = decoder.decode(body.bytes, StaticMeta.OUTER_BONAPORTABLE)
                } catch (MessageParserException e) {
                    error = 400
                    response.statusMessage = e.message
                    return
                }
                // process the request
                
                // send the response
                // ECHO for now
                if (false) {
                    error(500, '''error msg of the response''')
                    return
                }
                val end = System.currentTimeMillis
                val resp = encoder.encode(request, StaticMeta.OUTER_BONAPORTABLE)
                LOGGER.info("Processed request {} for tenant {} in {} ms with result code 0, response length is {}", request.ret$PQON, info2.tenantId, end - start, resp.length)
                response.end(Buffer.buffer(resp))
                
            ]
        ]
    }
}