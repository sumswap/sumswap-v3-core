// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.7.6;

import './Strings.sol';
import './BitMath.sol';
import './Base64.sol';

/// @title NFTSVG
/// @notice Provides a function for generating an SVG associated with a SummaV3swap NFT
library NFTSVG {
    using Strings for uint256;

    string constant curve1 = 'M1 1C41 41 105 105 145 145';
    string constant curve2 = 'M1 1C33 49 97 113 145 145';
    string constant curve3 = 'M1 1C33 57 89 113 145 145';
    string constant curve4 = 'M1 1C25 65 81 121 145 145';
    string constant curve5 = 'M1 1C17 73 73 129 145 145';
    string constant curve6 = 'M1 1C9 81 65 137 145 145';
    string constant curve7 = 'M1 1C1 89 57.5 145 145 145';
    string constant curve8 = 'M1 1C1 97 49 145 145 145';

    struct SVGParams {
        string quoteToken;
        string baseToken;
        address poolAddress;
        string quoteTokenSymbol;
        string baseTokenSymbol;
        string feeTier;
        int24 tickLower;
        int24 tickUpper;
        int24 tickSpacing;
        int8 overRange;
        uint256 tokenId;
        string color0;
        string color1;
        string color2;
        string color3;
        string x1;
        string y1;
        string x2;
        string y2;
        string x3;
        string y3;
    }

    function generateSVG(SVGParams memory params) internal pure returns (string memory svg) {
        /*
        address: "0xe8ab59d3bcde16a29912de83a90eb39628cfc163",
        msg: "Forged in SVG for SummaSwap in 2021 by 0xe8ab59d3bcde16a29912de83a90eb39628cfc163",
        sig: "0x2df0e99d9cbfec33a705d83f75666d98b22dea7c1af412c584f7d626d83f02875993df740dc87563b9c73378f8462426da572d7989de88079a382ad96c57b68d1b",
        version: "2"
        */
        return
            string(
                abi.encodePacked(
                    generateSVGDefs(params),
                    generateSVGCardMantle(params.quoteTokenSymbol, params.baseTokenSymbol, params.feeTier),
                    generageSvgCurve(params.tickLower, params.tickUpper, params.tickSpacing, params.overRange),
                    generateSVGPositionDataAndLocationCurve(
                        params.tokenId.toString(),
                        params.tickLower,
                        params.tickUpper
                    ),
                    generateSVGRareSparkle(params.tokenId, params.poolAddress),
                    '</svg>'
                )
            );
    }

    function generateSVGDefs(SVGParams memory params) private pure returns (string memory svg) {
        svg = string(
            abi.encodePacked(
                '<svg width="456" height="465" viewBox="0 0 456 465" xmlns="http://www.w3.org/2000/svg"',
                " xmlns:xlink='http://www.w3.org/1999/xlink'>",
                '<defs>',
                '<clipPath id="corners"><rect width="456" height="465" rx="10" ry="10" /></clipPath>',
                '<filter id="top-region-blur"><feGaussianBlur in="SourceGraphic" stdDeviation="50" /></filter>',
                '<linearGradient id="grad-up" x1="1" x2="0" y1="1" y2="0"><stop offset="0.0" stop-color="white" stop-opacity="1" />',
                '<stop offset=".9" stop-color="white" stop-opacity="0" /></linearGradient>',
                '<linearGradient id="grad-down" x1="0" x2="1" y1="0" y2="1"><stop offset="0.0" stop-color="white" stop-opacity="1" /><stop offset="0.9" stop-color="white" stop-opacity="0" /></linearGradient>',
                '<mask id="fade-up" maskContentUnits="objectBoundingBox"><rect width="1" height="1" fill="url(#grad-up)" /></mask>',
                '<mask id="fade-down" maskContentUnits="objectBoundingBox"><rect width="1" height="1" fill="url(#grad-down)" /></mask>',
                '<mask id="none" maskContentUnits="objectBoundingBox"><rect width="1" height="1" fill="white" /></mask>',
                '<linearGradient id="grad-symbol"><stop offset="0.7" stop-color="white" stop-opacity="1" /><stop offset=".95" stop-color="white" stop-opacity="0" /></linearGradient>',
                '<mask id="fade-symbol" maskContentUnits="userSpaceOnUse"><rect width="400px" height="200px" fill="url(#grad-symbol)" /></mask></defs>',
                // '<image  xlink:href="data:image/svg+xml;base64,',
                // Base64.encode(
                //     bytes(
                //         abi.encodePacked(
                //             "<svg xmlns='http://www.w3.org/2000/svg' height='100%' width='100%' id='svg' viewBox='0 0 1440 -2' class='transition duration-300 ease-in-out delay-150'>",
                //             "<path d='M 0,600 C 0,600 0,300 0,300 C 44.55357142857143,289.5062592047128 89.10714285714286,279.0125184094256 152,298 C 214.89285714285714,316.9874815905744 296.125,365.4561855670103 366,354 C 435.875,342.5438144329897 494.3928571428572,271.1627393225331 551,269 C 607.6071428571428,266.8372606774669 662.3035714285713,333.89285714285717 715,351 C 767.6964285714287,368.10714285714283 818.3928571428572,335.26583210603826 886,292 C 953.6071428571428,248.7341678939617 1038.1249999999998,195.0438144329897 1109,207 C 1179.8750000000002,218.9561855670103 1237.107142857143,296.5589101620029 1290,323 C 1342.892857142857,349.4410898379971 1391.4464285714284,324.72054491899854 1440,300 C 1440,300 1440,600 1440,600 Z' stroke='none' stroke-width='0' fill='#f9e3e1ff' class='transition-all duration-300 ease-in-out delay-150'/>",
                //             "</svg>"
                //         )
                //     )
                // ),
                '" x="0" y="0" width="456" height="465"/>',
                '<g clip-path="url(#corners)">',
                '<rect style="fill:rgba(255,255,255,0)" x="0px" y="0px" width="456px" height="465px" /></g>'
                // ' <g style="filter:url(#top-region-blur); transform:scale(0.5); transform-origin:center top;">',
                // '<rect fill="none" x="0px" y="0px" width="290px" height="500px" />',
                // '<ellipse cx="50%" cy="0px" rx="180px" ry="120px" fill="#DC143C" opacity="0.3" /></g></g>'
            )
        );
    }
    
    function generateSVGCardMantle(
        string memory quoteTokenSymbol,
        string memory baseTokenSymbol,
        string memory feeTier
    ) private pure returns (string memory svg) {
        svg = string(
            abi.encodePacked(
                '<g mask="url(#fade-symbol)"><rect fill="none" x="0px" y="0px" width="456px" height="200px" /> <text y="70px" x="32px" fill="#4854df" font-family="\'Courier New\', monospace" font-weight="200" font-size="30px">',
                quoteTokenSymbol,
                '/',
                baseTokenSymbol,
                '</text><text y="115px" x="32px" fill="#4854df" font-family="\'Courier New\', monospace" font-weight="200" font-size="30px">',
                feeTier,
                '</text></g>'
            )
        );
    }

    function generageSvgCurve(
        int24 tickLower,
        int24 tickUpper,
        int24 tickSpacing,
        int8 overRange
    ) private pure returns (string memory svg) {
        string memory fade = overRange == 1 ? '#fade-up' : overRange == -1 ? '#fade-down' : '#none';
        string memory curve = getCurve(tickLower, tickUpper, tickSpacing);
        svg = string(
            abi.encodePacked(
                '<g mask="url(',
                fade,
                ')"',
                ' style="transform:translate(172px,170px)">'
                '<rect x="-16px" y="-16px" width="180px" height="180px" fill="none" />'
                '<path d="',
                curve,
                '" stroke="rgba(207,226,255)" stroke-width="18px" fill="none" stroke-linecap="round" />',
                '</g><g mask="url(',
                fade,
                ')"',
                ' style="transform:translate(172px,170px)">',
                '<rect x="-16px" y="-16px" width="180px" height="180px" fill="none" />',
                '<path d="',
                curve,
                '" stroke="rgba(186,31,160,203)" fill="none" stroke-width="8px"  stroke-linecap="round" /></g>',
                generateSVGCurveCircle(overRange)
            )
        );
    }

    function getCurve(
        int24 tickLower,
        int24 tickUpper,
        int24 tickSpacing
    ) internal pure returns (string memory curve) {
        int24 tickRange = (tickUpper - tickLower) / tickSpacing;
        if (tickRange <= 4) {
            curve = curve1;
        } else if (tickRange <= 8) {
            curve = curve2;
        } else if (tickRange <= 16) {
            curve = curve3;
        } else if (tickRange <= 32) {
            curve = curve4;
        } else if (tickRange <= 64) {
            curve = curve5;
        } else if (tickRange <= 128) {
            curve = curve6;
        } else if (tickRange <= 256) {
            curve = curve7;
        } else {
            curve = curve8;
        }
    }

    function generateSVGCurveCircle(int8 overRange) internal pure returns (string memory svg) {
        string memory curvex1 = '173';
        string memory curvey1 = '171';
        string memory curvex2 = '317';
        string memory curvey2 = '315';
        if (overRange == 1 || overRange == -1) {
            svg = string(
                abi.encodePacked(
                    '<circle cx="',
                    overRange == -1 ? curvex1 : curvex2,
                    'px" cy="',
                    overRange == -1 ? curvey1 : curvey2,
                    'px" r="4px" fill="#f7f8fa" /><circle cx="',
                    overRange == -1 ? curvex1 : curvex2,
                    'px" cy="',
                    overRange == -1 ? curvey1 : curvey2,
                    'px" r="8px" fill="#f7f8fa" stroke="#FFB6C1" />'
                )
            );
        } else {
            svg = string(
                abi.encodePacked(
                    '<circle cx="',
                    curvex1,
                    'px" cy="',
                    curvey1,
                    'px" r="4px" fill="#f7f8fa" />',
                    '<circle cx="',
                    curvex2,
                    'px" cy="',
                    curvey2,
                    'px" r="4px" fill="#f7f8fa" />'
                )
            );
        }
    }
    
    function generateSVGPositionDataAndLocationCurve(
        string memory tokenId,
        int24 tickLower,
        int24 tickUpper
    ) private pure returns (string memory svg) {
        string memory tickLowerStr = tickToString(tickLower);
        string memory tickUpperStr = tickToString(tickUpper);
        (string memory xCoord, string memory yCoord) = rangeLocation(tickLower, tickUpper);
        svg = string(
             abi.encodePacked(
                ' <g style="transform:translate(29px, 344px)">',
                '<rect width="210px" height="26px" rx="8px" ry="8px" fill="rgba(195,191,238,0.5)" />',
                '<text x="12px" y="17px" font-family="\'Courier New\', monospace" font-size="18px" fill="#242a31"><tspan fill="#242a31">ID: </tspan>',
                tokenId,
                '</text></g>',
                ' <g style="transform:translate(29px, 384px)">',
                '<rect width="210px" height="26px" rx="8px" ry="8px" fill="rgba(195,191,238,0.5)" />',
                '<text x="12px" y="17px" font-family="\'Courier New\', monospace" font-size="18px" fill="#242a31"><tspan fill="#242a31">Min Tick: </tspan>',
                tickLowerStr,
                '</text></g>',
                ' <g style="transform:translate(29px, 424px)">',
                '<rect width="210px" height="26px" rx="8px" ry="8px" fill="rgba(195,191,238,0.5)" />',
                '<text x="12px" y="17px" font-family="\'Courier New\', monospace" font-size="18px" fill="#242a31"><tspan fill="#242a31">Max Tick: </tspan>',
                tickUpperStr,
                '</text></g>'
                '<g style="transform:translate(356px, 400px)">',
                '<rect width="36px" height="36px" rx="8px" ry="8px" fill="none"  stroke="#c3bfee" />',
                '<path stroke-linecap="round" d="M8 9C8.00004 22.9494 16.2099 28 27 28" fill="none" stroke="rgb(186, 31, 160)" />',
                '<circle style="transform:translate3d(',
                xCoord,
                'px, ',
                yCoord,
                'px, 0px)" cx="0px" cy="0px" r="4px" fill="rgb(94,75,211)"/></g>'
            )
        );
    }

    function tickToString(int24 tick) private pure returns (string memory) {
        string memory sign = '';
        if (tick < 0) {
            tick = tick * -1;
            sign = '-';
        }
        return string(abi.encodePacked(sign, uint256(tick).toString()));
    }

    function rangeLocation(int24 tickLower, int24 tickUpper) internal pure returns (string memory, string memory) {
        int24 midPoint = (tickLower + tickUpper) / 2;
        if (midPoint < -125_000) {
            return ('8', '7');
        } else if (midPoint < -75_000) {
            return ('8', '10.5');
        } else if (midPoint < -25_000) {
            return ('8', '14.25');
        } else if (midPoint < -5_000) {
            return ('10', '18');
        } else if (midPoint < 0) {
            return ('11', '21');
        } else if (midPoint < 5_000) {
            return ('13', '23');
        } else if (midPoint < 25_000) {
            return ('15', '25');
        } else if (midPoint < 75_000) {
            return ('18', '26');
        } else if (midPoint < 125_000) {
            return ('21', '27');
        } else {
            return ('24', '27');
        }
    }

    function generateSVGRareSparkle(uint256 tokenId, address poolAddress) private pure returns (string memory svg) {
        if (isRare(tokenId, poolAddress)) {
            svg = string(
                abi.encodePacked(
                    '<g style="transform:translate(300px, 400px)"><rect width="36px" height="36px" rx="8px" ry="8px" fill="none" stroke="#c3bfee" />',
                    '<g><path style="transform:translate(6px,6px)" d="M12 0L12.6522 9.56587L18 1.6077L13.7819 10.2181L22.3923 6L14.4341 ',
                    '11.3478L24 12L14.4341 12.6522L22.3923 18L13.7819 13.7819L18 22.3923L12.6522 14.4341L12 24L11.3478 14.4341L6 22.39',
                    '23L10.2181 13.7819L1.6077 18L9.56587 12.6522L0 12L9.56587 11.3478L1.6077 6L10.2181 10.2181L6 1.6077L11.3478 9.56587L12 0Z" fill="rgb(186, 31, 160)" />',
                    '<animateTransform attributeName="transform" type="rotate" from="0 18 18" to="360 18 18" dur="10s" repeatCount="indefinite"/></g></g>'
                )
            );
        } else {
            svg = '';
        }
    }

    function isRare(uint256 tokenId, address poolAddress) internal pure returns (bool) {
        bytes32 h = keccak256(abi.encodePacked(tokenId, poolAddress));
        return uint256(h) < type(uint256).max / (1 + BitMath.mostSignificantBit(tokenId) * 2);
    }
}
