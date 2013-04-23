#ifndef NATIVEUI_STREAMPREVIEW_H_
#define NATIVEUI_STREAMPREVIEW_H_

#include "Image.h"

namespace NativeUI
{
	class StreamPreview : public Widget
    {
    public:
        StreamPreview();

        virtual ~StreamPreview();

        void setAddress(const MAUtil::String& address);
        void setPort(const MAUtil::String& address);
        void setStreamState(bool enableStream);
    };
} // namespace NativeUI

#endif /* NATIVEUI_STREAMPREVIEW_H_ */
