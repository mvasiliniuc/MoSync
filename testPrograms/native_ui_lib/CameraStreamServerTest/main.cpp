#include <ma.h>
#include <mavsprintf.h>
#include <MAUtil/Moblet.h>
#include <NativeUI/Widgets.h>
#include <NativeUI/WidgetUtil.h>

using namespace MAUtil;
using namespace NativeUI;

#define BLACK_COLOR 0x000000
#define BTN_HEIGHT 80
#define BTN_WIDTH 180
#define SPACER 5
#define BTN_TEXT_START "Start broadcasting"
#define BTN_TEXT_STOP "Stop broadcasting"

/**
 * Moblet to be used as a template for a Native UI application.
 */
class NativeUIMoblet : public Moblet, public ButtonListener
{
public:
	/**
	 * The constructor creates the user interface.
	 */
	NativeUIMoblet()
	{
		createUI();
		mIsBroadcasting = false;
	}

	/**
	 * Destructor.
	 */
	virtual ~NativeUIMoblet()
	{
		mCameraWidget->stopPreview();
		mBroadcatsBtn->removeButtonListener(this);
		// All the children will be deleted.
		delete mScreen;
	}

	/**
	 * Create the user interface.
	 */
	void createUI()
	{
		mScreen = new Screen();

		mMainLayout = new RelativeLayout();
		mMainLayout->setBackgroundColor(BLACK_COLOR);
		mScreen->setMainWidget(mMainLayout);

		setupWidgets();
		arrangeWidgets();

		mScreen->show();
		mCameraWidget->setCurrentCameraByIndex(1);
		mCameraWidget->startPreview();
	}
	void setupWidgets()
	{
		mCameraWidget = new Camera();
		mMainLayout->addChild(mCameraWidget);

		mBroadcatsBtn = new Button();
		mBroadcatsBtn->setText(BTN_TEXT_START);
		mBroadcatsBtn->addButtonListener(this);
		mMainLayout->addChild(mBroadcatsBtn);
	}

	void arrangeWidgets()
	{
		MAExtent size = maGetScrSize();

		int screenWidth = EXTENT_X(size);
		int screenHeight = EXTENT_Y(size);

		mCameraWidget->setPosition(0, 0);
		mCameraWidget->setWidth(screenWidth);
		mCameraWidget->setHeight(screenHeight);

		mBroadcatsBtn->setPosition((screenWidth - BTN_WIDTH)/2,
				screenHeight - BTN_HEIGHT - SPACER);
		mBroadcatsBtn->setWidth(BTN_WIDTH);
		mBroadcatsBtn->setHeight(BTN_HEIGHT);
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

	/**
	* This method is called if the touch-up event was inside the
	* bounds of the button.
	* @param button The button object that generated the event.
	*/
	virtual void buttonClicked(Widget* button)
	{
		if ( !mIsBroadcasting )
		{
			// TODO Replace this with proper syscalls
			int* mCameraPreviewBuffer = new int[40];

			MARect previewRect = {0,0,40,40};

			maCameraPreviewEventEnable(MA_CAMERA_PREVIEW_FRAME, mCameraPreviewBuffer, &previewRect);
			mBroadcatsBtn->setText(BTN_TEXT_STOP);
			mIsBroadcasting = true;
		}
		else
		{
			// TODO Replace this with proper syscalls
			maCameraPreviewEventDisable();
			mBroadcatsBtn->setText(BTN_TEXT_START);
			mIsBroadcasting = false;
		}
	}

private:
    Screen* mScreen;
    RelativeLayout* mMainLayout;
    Button* mBroadcatsBtn;
    Camera* mCameraWidget;
    bool mIsBroadcasting;
};

/**
 * Main function that is called when the program starts.
 */
extern "C" int MAMain()
{
	Moblet::run(new NativeUIMoblet());
	return 0;
}
