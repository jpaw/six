package de.jpaw.six;

import io.vertx.core.Vertx;
import io.vertx.core.http.HttpServerResponse;
import io.vertx.ext.web.Router;
import io.vertx.ext.web.RoutingContext;

/** A ServiceModule is a microservice like portion which owns its own
 * UI and provides http based paths.
 * 
 * Modules are detected via Jdp
 * @author mbi
 *
 */
public interface IServiceModule extends Comparable<IServiceModule> {
    int getExceptionOffset();
    String getModuleName();
    Router createRouter(Vertx vertx);
    default String getMountPoint() { return "/api/"; }
    
    @Override
    default int compareTo(IServiceModule that) {
        int num = getExceptionOffset() - that.getExceptionOffset();
        return num != 0 ? num : getModuleName().compareTo(that.getModuleName());
    }
    
    static void error(RoutingContext ctx, int errorCode) {
        HttpServerResponse r = ctx.response();
        r.setStatusCode(errorCode);
        r.end();
    }
    
    static void error(RoutingContext ctx, int errorCode, String msg) {
        HttpServerResponse r = ctx.response();
        r.setStatusCode(errorCode);
        r.setStatusMessage(msg);
        r.end();
    }
}
