/*
 *validate.h
 *   Copyright 2000-2002, eSellerate Inc.
 *   All rights reserved worldwide.
 */

#ifndef _VALIDATE_API_H_
#define _VALIDATE_API_H_

#ifdef __cplusplus
extern "C" {
#endif


typedef unsigned char* eSellerate_String;

typedef short eSellerate_DaysSince2000;

eSellerate_DaysSince2000 eSellerate_ValidateSerialNumber (
  eSellerate_String serialNumber, /* ASCII Pascal string                   */
  eSellerate_String nameBasedKey, /* ASCII Pascal string (nil if unneeded) */
  eSellerate_String extraDataKey, /* ASCII Pascal string (nil if unneeded) */
  eSellerate_String publisherKey  /* ASCII Pascal string (nil if unneeded) */
);
/*
 * return codes:
 *   if valid: date (days since January 1 2000) of expiration or (non-expiring) purchase
 *   if invalid: 0
 */

eSellerate_DaysSince2000 eWeb_ValidateSerialNumber (
  const char	*serialNumber, /* "C" string                   */
  const char	*nameBasedKey, /* "C" string (nil if unneeded) */
  const char	*extraDataKey, /* "C" string (nil if unneeded) */
  const char	*publisherKey  /* "C" string (nil if unneeded) */
);
/*
 * return codes:
 *   if valid: date (days since January 1 2000) of expiration or (non-expiring) purchase
 *   if invalid: 0
 */


eSellerate_DaysSince2000 eSellerate_Today ( ); /* days from 1/1/2000 to today */

#ifdef __cplusplus
}
#endif

#endif