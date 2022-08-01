
#define MY_VID	0x0314 //0x0314
#define MY_PID	0xE457 //0xE457

struct libusb_device **devs;
struct libusb_device_handle *MyLibusbDeviceHandle = NULL;
struct libusb_device_descriptor desc;

typedef enum { 	PIN2DMD ,
		PIN2DMD_XL ,
		PIN2DMD_HD
} DeviceType;


volatile bool dump_running = false;
volatile DeviceType deviceType = PIN2DMD;


	// global instance
USBClass usb;

USBClass::USBClass() {
}

USBClass::~USBClass() {
}

int USBClass::setup () {

	int ret = 0;

		libusb_init(NULL); /* initialize the library */

		int device_count = libusb_get_device_list(NULL, &devs);

		//Now look through the list that we just populated.  We are trying to see if any of them match our device.
		for (int i = 0; i < device_count; i++) {
			libusb_get_device_descriptor(devs[i], &desc);
			if(MY_VID == desc.idVendor && MY_PID == desc.idProduct) {
				libusb_open(devs[i], &MyLibusbDeviceHandle);
				break;
			}
		}


		if(MyLibusbDeviceHandle == NULL)
		{
			//wxMessageBox( wxT("Device not found !"));
		return 0;
		}


		unsigned char *product;
		product = (unsigned char *)malloc(256);
		ret= libusb_get_string_descriptor_ascii(MyLibusbDeviceHandle, desc.iProduct, product, 256);
		const char *string=NULL;
		string = (const char*) product;
		if (ret > 0) {
			if (strcmp(string, "PIN2DMD") == 0) {
				ret = 2;
				deviceType = PIN2DMD;
			}
			else if (strcmp(string, "PIN2DMD XL") == 0) {
				ret = 3;
				deviceType = PIN2DMD_XL;
			}
			else if (strcmp(string, "PIN2DMD HD") == 0) {
				ret = 4;
				deviceType = PIN2DMD_HD;
			}
			else {
				ret = 1;
				deviceType = PIN2DMD;
			}
		}
		free(product);

		libusb_free_device_list(devs, 1);

		if(libusb_claim_interface(MyLibusbDeviceHandle, 0) < 0)  //claims the interface with the Operating System
		{
		//Closes a device opened since the claim interface is failed.
		libusb_close(MyLibusbDeviceHandle);
		return 0;
		}

		return ret;
}

DeviceType USBClass::getDeviceType() {
	return deviceType;
}

int USBClass::release() {

	libusb_release_interface(MyLibusbDeviceHandle, 0);
	//closes a device opened
	libusb_close(MyLibusbDeviceHandle);

	MyLibusbDeviceHandle = NULL;

	return 1;

}

bool USBClass::sendUSB (unsigned char *packetbuffer,int packetsize) {
	if (!this->setup()) { return 0; }
	libusb_bulk_transfer(MyLibusbDeviceHandle, 0x01, packetbuffer , packetsize, NULL, 1000);
	this->release();
	return true;
}


void USBClass::receiveDump (unsigned char mode, wxString pathName) {

				int ret;
				unsigned char numberOfPlanes = 3;
				bool rawDump = false;
				int planeSize = 512;
				FILE *file, *fileRaw;
				char fileName [35];
				char fileNameRaw [35];
				wxString pathNameRaw;
				unsigned char *OutputPacketBuffer;
				unsigned char *ReceivePacketBuffer;

				const DWORD tick;
				time_t actTime;


				actTime = time(NULL);

				if (actTime != -1)
				{
					strftime(fileName, sizeof(fileName), "/%d%m%y_%H%M%S_pin2dmd_dump.txt", gmtime(&actTime));
					pathNameRaw = pathName.Clone();
					pathName.append(fileName);
					if (rawDump) {
						strftime(fileNameRaw, sizeof(fileNameRaw), "/%d%m%y_%H%M%S_pin2dmd_dump.raw", gmtime(&actTime));
						pathNameRaw.append(fileNameRaw);
						fileRaw = fopen(pathNameRaw.mb_str(), "ab");
						if (fileRaw)
						{
							fputc(0x52, fileRaw); //R
							fputc(0x41, fileRaw); //A
							fputc(0x57, fileRaw); //W
							fputc(0x00, fileRaw); //
							fputc(0x01, fileRaw); // version
							fputc(128, fileRaw);  // width
							fputc(32, fileRaw);   // height
							fputc(numberOfPlanes, fileRaw);
							fclose(fileRaw);
						}
					}
				}
				ret = this->setup();

				if (ret == 0) { return; }

				OutputPacketBuffer = (unsigned char *)malloc(64);
				memset(OutputPacketBuffer, 0, 64);

				ReceivePacketBuffer = (unsigned char *)malloc((numberOfPlanes * planeSize) + 1);
				memset(ReceivePacketBuffer, 0, (numberOfPlanes * planeSize) + 1);

				OutputPacketBuffer[0] = 0x01;
				OutputPacketBuffer[1] = 0xc3;
				OutputPacketBuffer[2] = 0xe8;
				OutputPacketBuffer[3] = numberOfPlanes;


				libusb_bulk_transfer(MyLibusbDeviceHandle, 0x01, OutputPacketBuffer, 64, NULL, 2000);
				ret = libusb_bulk_transfer(MyLibusbDeviceHandle, 0x81, ReceivePacketBuffer, (OutputPacketBuffer[3] * planeSize) + 1, NULL, 10000);

				tick = GetTickCount();

				if (rawDump) {
					fileRaw = fopen(pathNameRaw.mb_str(), "ab");
					if (fileRaw){
						fwrite(&tick, 1, 4, fileRaw);
						fwrite(ReceivePacketBuffer, 1, numberOfPlanes * planeSize, fileRaw);
						fclose(fileRaw);
					}
				}


				 this->release();

				 free(ReceivePacketBuffer);
				 free(OutputPacketBuffer);
}
;
