package de.jpaw.six;

import de.jpaw.bonaparte.core.BonaPortable;
import de.jpaw.bonaparte.pojos.meta.ObjectReference;
import de.jpaw.util.ApplicationException;

public interface IRequestProcessor<RQ extends BonaPortable, RS extends BonaPortable> {
    ObjectReference getRequestRef();
    ObjectReference getResponseRef();
    RS execute(RQ rq) throws ApplicationException;
    int getReturnCode(RS rs);
}
