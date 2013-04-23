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
#define TEXT_WIDTH 280
#define TEXT_HEIGHT 60
#define SPACER 5
#define MEDALION_WIDTH 230
#define MEDALION_HEIGHT 280
#define CONNECT_TEXT "Connect"
#define DISCONECT_TEXT "Disconnect"

/**
 * Moblet to be used as a template for a Native UI application.
 */
class NativeUIMoblet : public Moblet, public ButtonListener, public EditBoxListener
{
public:
	/**
	 * The constructor creates the user interface.
	 */
	NativeUIMoblet()
	{
		createUI();
		mIsConnected = false;
	}

	/**
	 * Destructor.
	 */
	virtual ~NativeUIMoblet()
	{
		mCameraWidget->stopPreview();
		mConnectBtn->removeButtonListener(this);

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
		// mStreamPreview
		mStreamPreview = new StreamPreview();
		mStreamPreview->setBackgroundColor(BLACK_COLOR);
		mMainLayout->addChild(mStreamPreview);

		// Camera
		mCameraWidget = new Camera();
		mMainLayout->addChild(mCameraWidget);

		// Connect button
		mConnectBtn = new Button();
		mConnectBtn->setText(CONNECT_TEXT);
		mConnectBtn->addButtonListener(this);
		mMainLayout->addChild(mConnectBtn);

		mIpInput = new EditBox();
		mIpInput->addEditBoxListener(this);
		mIpInput->setPlaceholder("Enter IP address");
		mIpInput->setInputMode(EDIT_BOX_INPUT_MODE_NUMERIC);
		mIpInput->setInputMode(EDIT_BOX_INPUT_MODE_SINGLE_LINE);
		mMainLayout->addChild(mIpInput);
	}

	void arrangeWidgets()
	{
		MAExtent size = maGetScrSize();

		int screenWidth = EXTENT_X(size);
		int screenHeight = EXTENT_Y(size);

		mStreamPreview->setPosition(0, 0);
		mStreamPreview->setWidth(screenWidth);
		mStreamPreview->setHeight(screenHeight);

		mCameraWidget->setPosition(2*SPACER, 2*SPACER);
		mCameraWidget->setWidth(MEDALION_WIDTH);
		mCameraWidget->setHeight(MEDALION_HEIGHT);

		mConnectBtn->setPosition((screenWidth - BTN_WIDTH)/2,
				screenHeight - BTN_HEIGHT - SPACER);
		mConnectBtn->setWidth(BTN_WIDTH);
		mConnectBtn->setHeight(BTN_HEIGHT);

		mIpInput->setPosition(screenWidth - TEXT_WIDTH - SPACER, 2*SPACER);
		mIpInput->setWidth(TEXT_WIDTH);
		mIpInput->setHeight(TEXT_HEIGHT);
	}

	void editBoxReturn(EditBox* editBox)
	{
		 mIpInput->hideKeyboard();
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
		if ( button == mConnectBtn )
		{
			if ( !mIsConnected )
			{
				MAUtil::String ipAdr = mIpInput->getText();
				if (ipAdr.length() > 0)
				{
					mStreamPreview->setAddress(ipAdr);
					mStreamPreview->setStreamState(true);
					mIpInput->setVisible(false);
					mConnectBtn->setText(DISCONECT_TEXT);
					mIsConnected = true;
				}
			}
			else
			{
				mConnectBtn->setText(CONNECT_TEXT);
				mStreamPreview->setStreamState(false);
				mIpInput->setVisible(true);
				mIsConnected = false;
			}
		}
	}

private:
    Screen* mScreen;
    RelativeLayout* mMainLayout;

    Button* mConnectBtn;
    EditBox* mIpInput;

    Camera* mCameraWidget;
    StreamPreview* mStreamPreview;

    bool mIsConnected;
};

/**
 * Main function that is called when the program starts.
 */
extern "C" int MAMain()
{
	Moblet::run(new NativeUIMoblet());
	return 0;
}
