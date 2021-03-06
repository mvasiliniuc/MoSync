#include <ma.h>
#include <mavsprintf.h>
#include <MAUtil/Moblet.h>
#include <NativeUI/WidgetUtil.h>

using namespace MAUtil;
using namespace NativeUI;

#include "MoSyncCamController.h"

namespace MoSyncCamera
{
	/**
	 * Moblet to be used as a template for a Native UI application.
	 */
	class CameraMoblet : public Moblet
	{
	public:
		CameraMoblet()
		{
			mMoSyncCameraController = new MoSyncCamController();

			mMoSyncCameraController->displayMainScreen();
		}

		virtual ~CameraMoblet()
		{
			delete mMoSyncCameraController;
		}

		/**
		 * Called when a key is pressed.
		 */
		void keyPressEvent(int keyCode, int nativeCode)
		{
			if (MAK_BACK == keyCode || MAK_0 == keyCode)
			{
				// Call close to exit the application.
				close();
			}
		}

	private:
		MoSyncCamController* mMoSyncCameraController;
	};
} // MoSyncCamera

/**
 * Main function that is called when the program starts.
 */
extern "C" int MAMain()
{
	MoSyncCamera::CameraMoblet *cameraMoblet = new MoSyncCamera::CameraMoblet();

	Moblet::run( cameraMoblet );

	delete cameraMoblet;

	return 0;
}
