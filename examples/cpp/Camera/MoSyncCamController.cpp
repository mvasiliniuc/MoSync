/*
 Copyright (C) 2013 MoSync AB

 This program is free software; you can redistribute it and/or
 modify it under the terms of the GNU General Public License,
 version 2, as published by the Free Software Foundation.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program; if not, write to the Free Software
 Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 MA 02110-1301, USA.
 */

/**
 * @file MoSyncCamController.cpp
 * @author Mircea Vasiliniuc
 * @date 16 March 2013
 *
 * @brief Application's main controller.
 */

#include <NativeUI/Screen.h>
#include <MAUtil/Environment.h>

#include "MoSyncCamController.h"
#include "Screens/ScreenUtils.h"

namespace MoSyncCamera
{
	MoSyncCamController::MoSyncCamController():
		mCameraScreen(NULL),
		mImageViewerScreen(NULL),
		mForwardTransition(MAW_TRANSITION_TYPE_NONE),
		mBackwardTransition(MAW_TRANSITION_TYPE_NONE),
		mDisplayedScreen(-1),
		mDisplayedImageHandle(0),
		mLastSnapshotDataHandle(0)
	{
		mCameraScreen = new CameraScreen(*this);
		mImageViewerScreen = new ImageViewerScreen(*this);

		mCameraScreen->registerCameraListener(this);
		setScreenTransitions();
	}


	MoSyncCamController::~MoSyncCamController()
	{
		if ( mDisplayedImageHandle > 0 )
		{
			maDestroyPlaceholder(mDisplayedImageHandle);
		}

		if ( mLastSnapshotDataHandle > 0 )
		{
			maDestroyPlaceholder(mLastSnapshotDataHandle);
		}

		mCameraScreen->unregisterCameraListener(this);

		delete mCameraScreen;
		delete mImageViewerScreen;
	}


	void MoSyncCamController::displayMainScreen()
	{
		if ( !isDisplayed(*mCameraScreen) )
		{
			mCameraScreen->show();

			setCurrentScreen(*mCameraScreen);
		}
	}


	void MoSyncCamController::snapshotDisplayRequested()
	{
		if ( !isDisplayed(*mImageViewerScreen) )
		{
			if ( mLastSnapshotDataHandle > 0 )
			{
				mDisplayedImageHandle = maCreatePlaceholder();

				maCreateImageFromData(
					mDisplayedImageHandle,
					mLastSnapshotDataHandle,
					0,
					maGetDataSize(mLastSnapshotDataHandle));

				mImageViewerScreen->setImageWithData(mDisplayedImageHandle);
				mImageViewerScreen->showWithTransition(mForwardTransition, SCREEN_TRANSITION_DURATION);

				setCurrentScreen(*mImageViewerScreen);
			}
		}
	}


	void MoSyncCamController::snapshotRequested()
	{
		mCameraScreen->showSnapshotInProgress();

		if ( mLastSnapshotDataHandle > 0 )
		{
			maDestroyPlaceholder(mLastSnapshotDataHandle);
			mLastSnapshotDataHandle = 0;
		}
		mLastSnapshotDataHandle = maCreatePlaceholder();

		mCameraScreen->takeSnapshot(mLastSnapshotDataHandle);
	}


	void MoSyncCamController::imageViewingDone()
	{
		if ( !isDisplayed(*mCameraScreen) )
		{
			mCameraScreen->showWithTransition(mBackwardTransition, SCREEN_TRANSITION_DURATION);

			if ( mDisplayedImageHandle > 0 )
			{
				maDestroyPlaceholder(mDisplayedImageHandle);
				mDisplayedImageHandle = 0;
			}

			setCurrentScreen(*mCameraScreen);
		}
	}


	void MoSyncCamController::exportImageToGalleryRequested()
	{
		maAlert("Save image", "Image saving is not yet available", "OK", NULL, NULL);
	}


	void MoSyncCamController::snapshotFinished( const NativeUI::CameraSnapshotData& imageData )
	{
		bool snapshotIsAvailable = true;
		if ( imageData.resultCode != MA_CAMERA_RES_OK )
		{
			maAlert("Camera", "Snapshot failed", "OK", NULL, NULL);
			snapshotIsAvailable = false;

			if ( mLastSnapshotDataHandle > 0 )
			{
				maDestroyPlaceholder(mLastSnapshotDataHandle);
				mLastSnapshotDataHandle = 0;
			}
		}
		mCameraScreen->hideSnapshotInProgress(snapshotIsAvailable);
	}


	MAWScreenTransitionType MoSyncCamController::setScreenTransitions()
	{
		switch (MAUtil::Environment::getEnvironment().getCurrentPlatform())
		{
		case MAUtil::OS_IOS:
			mForwardTransition = MAW_TRANSITION_TYPE_FLIP_FROM_LEFT;
			mBackwardTransition = MAW_TRANSITION_TYPE_FLIP_FROM_RIGHT;
			break;
		case MAUtil::OS_ANDROID:
			mForwardTransition = MAW_TRANSITION_TYPE_SLIDE_LEFT;
			mBackwardTransition = MAW_TRANSITION_TYPE_SLIDE_RIGHT;
			break;
		case MAUtil::OS_WIN:
			mForwardTransition = MAW_TRANSITION_TYPE_SWIVEL_IN;
			mBackwardTransition = MAW_TRANSITION_TYPE_SWIVEL_OUT;
			break;
		default:
			mForwardTransition = MAW_TRANSITION_TYPE_NONE;
			mBackwardTransition = MAW_TRANSITION_TYPE_NONE;
			break;
		}
	}

	void MoSyncCamController::setCurrentScreen( const NativeUI::Screen& currentScreen )
	{
		mDisplayedScreen = currentScreen.getWidgetHandle();
	}

	bool MoSyncCamController::isDisplayed( const NativeUI::Screen& currentScreen )
	{
		return mDisplayedScreen == currentScreen.getWidgetHandle();
	}
} // MoSyncCamera
