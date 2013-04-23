#include "StreamPreview.h"

namespace NativeUI
{
	StreamPreview::StreamPreview(): Widget("StreamPreview")
	{
	}

	StreamPreview::~StreamPreview()
	{
	}

	void StreamPreview::setAddress(const MAUtil::String& address)
	{
		this->setProperty(MAW_STREAM_PREVIEW_ADDR, address);
	}

	void StreamPreview::setPort(const MAUtil::String& port)
	{
		this->setProperty(MAW_STREAM_PREVIEW_PORT, port);
	}

	void StreamPreview::setStreamState(bool enableStream)
	{
		if ( enableStream )
		{
			this->setProperty(MAW_STREAM_PREVIEW_ENABLED, "true");
		}
		else
		{
			this->setProperty(MAW_STREAM_PREVIEW_ENABLED, "false");
		}
	}
} // namespace NativeUI
