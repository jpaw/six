package de.jpaw.six;

import de.jpaw.util.CharTestsASCII;
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
    
    static String asciiSubString(String s, int maxLength) {
        int max = s.length() < maxLength ? s.length() : maxLength;
        for (int i = 0; i < max; ++i) {
            if (!CharTestsASCII.isAsciiPrintable(s.charAt(i)))
                return s.substring(0, i);
        }
        return s;   // whole string is printable ASCII
    }
    
    static void error(RoutingContext ctx, int errorCode) {
        HttpServerResponse r = ctx.response();
        r.setStatusCode(errorCode);
        r.end();
    }
    
    static void error(RoutingContext ctx, int errorCode, String msg) {
        HttpServerResponse r = ctx.response();
        r.setStatusCode(errorCode);
        r.setStatusMessage(asciiSubString(msg, 200));
        r.end();
    }
}
