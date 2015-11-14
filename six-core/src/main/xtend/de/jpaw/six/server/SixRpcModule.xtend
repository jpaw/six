package de.jpaw.six.server

import de.jpaw.bonaparte.core.BonaPortable
import de.jpaw.bonaparte.core.MessageParserException
import de.jpaw.bonaparte.core.StaticMeta
import de.jpaw.bonaparte.pojos.api.auth.JwtInfo
import de.jpaw.bonaparte8.vertx3.IMessageCoderFactory
import de.jpaw.dp.Dependent
import de.jpaw.dp.Inject
import de.jpaw.dp.Named
import de.jpaw.six.IRequestProcessor
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
class RpcModule<RQ extends BonaPortable, RS extends BonaPortable> implements IServiceModule {
    private static final Logger LOGGER = LoggerFactory.getLogger(SixServer)
    
    @Inject private IMessageCoderFactory<BonaPortable, byte[]> coderFactory
    @Inject private IRequestProcessor<RQ, RS> requestProcessor;
    
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
                    LOGGER.error("No user defined or of bad type: Missing auth handler for rpc?")
                    error(500, "No user defined or of bad type: Missing auth handler?")
                    return
                }
                val jwtInfo = info as JwtInfo
                val ct = request.headers.get(CONTENT_TYPE)
                if (ct === null) {
                    error(415, "Content-Type not specified")
                    return
                }
                // decode the payload
                val decoder = coderFactory.getDecoderInstance(ct)
                val encoder = coderFactory.getEncoderInstance(ct)
                if (decoder === null || encoder === null) {
                    error(415, '''Content-Type «ct» not supported for path /rpc''')
                    return
                }
                val ctx = it
                vertx.<Void>executeBlocking([
                    try {
                        val request  = decoder.decode(ctx.body.bytes, requestProcessor.requestRef)
                        val response = requestProcessor.execute(request as RQ)
                        val respMsg  = encoder.encode(response, requestProcessor.responseRef)
                        val end = System.currentTimeMillis
                        LOGGER.info("Processed request {} for tenant {} in {} ms with result code {}, response length is {}",
                            request.ret$PQON, jwtInfo.tenantId, end - start, requestProcessor.getReturnCode(response), respMsg.length
                        )
                        ctx.response.end(Buffer.buffer(respMsg))
                    } catch (MessageParserException e) {
                        ctx.error(400, e.message)
                    } catch (Exception e) {
                        ctx.error(500, e.message)
                    }
                    complete()
                ], [])
            ]
        ]
    }
}