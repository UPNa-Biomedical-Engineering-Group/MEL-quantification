# MEL quantification

ImageJ/Fiji macros for quantifying marker expression level (MEL) in haematoxylin-DAB immunohistochemistry (IHC) images.

Within a user-defined tissue or tumour region, the workflow measures:

- the area occupied by a selected cellular compartment (nuclei, cytoplasm,
  or membrane); and
- the mean signal in the deconvolved DAB channel within that compartment.

<div align="center">
  <table>
    <tr>
      <td align="center" bgcolor="#f6f8fa" style="border: 1px solid #d0d7de; border-radius: 8px; padding: 14px;">
        <img src="docs/figures/workflow_overview.png" alt="General workflow for MEL quantification" width="850">
        <br>
        <div style="background-color: #eaeef2; border-left: 4px solid #9bb8d8; color: #afc6e0; margin-top: 12px; padding: 9px 14px; text-align: left;">
          <strong>Workflow overview.</strong>
          From the original RGB IHC image to region definition, colour
          deconvolution, compartment segmentation, and MEL quantification.
        </div>
      </td>
    </tr>
  </table>
</div>

## Repository structure

```text
MEL_quantification/
|-- README.md
|-- LICENSE
|-- docs/
|   `-- figures/
|       `-- workflow_overview.png
`-- plugin/
    |-- run_gui.ijm
    |-- nuclei/
    |   |-- nuclear.ijm
    |   |-- nuclear_single.ijm
    |   |-- nuclear_ROI.ijm
    |   |-- nuclear_tissue.ijm
    |   `-- nuclear_whole_tissue.ijm
    |-- cytoplasm/
    |   |-- cytoplasm.ijm
    |   |-- cytoplasm_single.ijm
    |   |-- cytoplasm_ROI.ijm
    |   |-- cytoplasm_tissue.ijm
    |   `-- cytoplasm_whole_tissue.ijm
    `-- membrane/
        |-- membrane.ijm
        |-- membrane_single.ijm
        |-- membrane_ROI.ijm
        |-- membrane_tissue.ijm
        `-- membrane_whole_tissue.ijm
```

## What the method does

For each RGB IHC image, the workflow:

1. defines the region in which measurements are made;
2. separates haematoxylin and DAB with ImageJ's `H&E DAB` colour
   deconvolution vector;
3. segments the selected cellular compartment; and
4. measures compartment area and mean DAB intensity.

The method supports three compartments:

- **Nuclei:** haematoxylin-positive objects.
- **Cytoplasm:** the selected tissue/tumour region after removal of
  detected and dilated nuclei.
- **Membrane:** objects obtained with a marker-controlled watershed
  driven by haematoxylin and strongly DAB-positive seeds.

## Measurement definition

For mask-based analyses, the area calculations are:

```text
compartment area (um^2) = compartment area (pixels) * r^2
compartment area (%)    = 100 * compartment area (um^2)
                           / analysed-region area (um^2)
```

`r` is the image scale in micrometres per pixel. The mean DAB value is
measured after the macro inverts the deconvolved DAB channel. It is
therefore the mean intensity of the inverted DAB image used by the macro,
not a separately calibrated optical-density measurement.

## Analysis modes

The launcher presents three choices:

| Choice | Options | Meaning |
|---|---|---|
| Analysis mode | Single image; Batch mode | Process one image or all matching images in a folder |
| Region to analyse | Whole tissue; ROI from mask; Manual ROI | Define the region used for segmentation and measurement |
| Structure | Nuclei; Cytoplasm; Membrane | Select the compartment to quantify |

Manual ROI is available only in single-image mode. The macro selected by
the launcher is determined by these choices:

| Filename suffix | Input | Region definition | Processing |
|---|---|---|---|
| `_whole_tissue` | One original image | Automatic tissue threshold | Single image |
| `_tissue` | Folder of original images | Automatic tissue threshold | Batch |
| `_single` | One original image and one label mask | External tumour mask | Single image |
| `_ROI` | One original image | Freehand ROI drawn by the user | Single image |
| No suffix | Folder of images and folder of label masks | External tumour mask | Batch |

## Algorithm

### Nuclei

The macro thresholds the deconvolved haematoxylin channel, fills holes,
applies a median filter, and uses watershed to separate touching objects.
`Analyze Particles` then excludes objects outside the configured minimum
and maximum areas. The resulting nuclear ROI is used to measure nuclear
area and DAB intensity.

### Cytoplasm

The macro detects nuclei using the nuclear workflow and dilates the
nuclear ROI. Boolean operations between the selected tissue/tumour region
and the dilated nuclei produce the cytoplasmic ROI. Cytoplasm area and
mean DAB intensity are then measured in that ROI.

### Membrane

The macro generates seeds from local maxima in the haematoxylin channel
and from maxima in strongly DAB-positive regions. It applies a
marker-controlled watershed to the inverted DAB-derived edge image inside
the selected region. Watershed boundaries are eroded and filtered by
minimum object size before membrane area and mean DAB intensity are
measured.

The `blue` and `brown` deconvolved channels, nuclei masks, cytoplasm ROIs,
watershed seeds, and membrane masks are intermediate images created during
processing. They are not additional input files.

## Input data

### Original IHC image

The original image is the RGB brightfield image containing haematoxylin
and DAB staining. It is the image from which the DAB measurement is made.

Required conditions:

- RGB format compatible with the `H&E DAB` deconvolution vector;
- `.tif` extension for batch mode (the current macros check for lowercase
  `.tif`);
- the same pixel dimensions as its label mask when mask mode is used; and
- a known pixel scale supplied through `Ratio micra/pixel`.

Do not use a deconvolved channel, a binary nuclei mask, or a JPEG quality
control overlay as the original image.

### External tumour label mask

An external mask is required only for **ROI from mask**. It must be a label
image in which pixel values represent regions such as background,
non-tumour tissue, and tumour. It is not a screenshot, an RGB copy of the
original image, or a mask of the nuclei.

For batch mask analysis, image and mask files must have exactly the same
filename and extension and must be stored in separate parallel folders:

```text
images/
|-- case_001.tif
`-- case_002.tif

masks/
|-- case_001.tif
`-- case_002.tif
```

For `case_001.tif`, the macros open the image from `images/` and the mask
from `masks/`. A different basename, extension, or folder layout will
cause the mask lookup to fail or select the wrong file. The single-image
macros ask for the original image first and the corresponding segmentation
image second.

The mask macros convert the label image to 8-bit and subtract 1 before
selecting `Tumor label`. With the default `Tumor label = 1`, tumour pixels
encoded as value 2 in the file are selected after this adjustment. This
is an implementation detail: inspect numeric pixel values in Fiji rather
than inferring labels from display colours.

## Parameters

The following are the parameters exposed by the current macros. Defaults
are starting values encoded in the scripts, not universal biological
constants.

| Parameter | Used by | Function | Default |
|---|---|---|---:|
| `Ratio micra/pixel` (`r`) | All variants | Converts pixel areas to um^2 | 0.502 |
| `Tumor label` (`labT`) | Mask variants | Label selected as tumour after the internal subtraction | 1 |
| `Nuclei threshold` (`thBlue`) | Nuclei, cytoplasm | Upper threshold on the deconvolved haematoxylin channel | 190 nuclei; 100 cytoplasm |
| `Nuclei threshold` (`thBlue`) | Membrane | Upper threshold used for haematoxylin seed generation | 140 |
| `Min nuclei size` (`minCellSize`) | Nuclei, cytoplasm | Minimum accepted nuclear particle area in pixels | 30 |
| `Max nuclei size` (`maxCellSize`) | Nuclei, cytoplasm | Maximum accepted nuclear particle area in pixels | 15000 |
| `Prominence for nuclei detection` (`prominence`) | Membrane | Prominence used by `Find Maxima` for seeds | 5 |
| `GLUT threshold` (`thBrown`) | Membrane | Threshold for strongly DAB-positive seed regions | 130 |
| `Min membrane size` (`minMembSize`) | Membrane | Minimum accepted membrane particle area in pixels | 50 |

## Outputs

The three mask-based batch macros have an active file-based export:

- `plugin/nuclei/nuclear.ijm`;
- `plugin/cytoplasm/cytoplasm.ijm`; and
- `plugin/membrane/membrane.ijm`.

They append one row per analysed image to
`QuantificationResults.xls`. Depending on the compartment, the table
contains:

- `Label`: original image filename;
- `Tumour area (um2)`: area of the selected tumour region;
- `Nuclei area in tumour (%)`, `Cytoplasm area in tumour (%)`, or
  `Membrane area in tumour (%)`;
- `Iavg nuclei`, `Iavg cytoplasm`, or `Iavg membrane`; and
- additional classification fields in variants that implement them.

The output folders are created inside the selected mask directory:

```text
Quantification_results/
|-- QuantificationResults.xls
`-- case_001_analyzed.jpg
```

For cytoplasm:

```text
Quantification_results_cytoplasmic/
|-- QuantificationResults.xls
`-- case_001_analyzed.jpg
```

For membrane:

```text
Membrane_segmentations/
`-- case_001_membraneSegmentation.jpg
```

The JPEG files are quality-control overlays with the detected compartment
drawn in red over the original image. They are output figures, not input
label masks.

### Requirements

- Fiji with a current ImageJ 1.x installation;
- the Fiji **Colour Deconvolution** command; and
- **Marker-controlled Watershed** for membrane analysis. If unavailable,
  enable the MorphoLibJ update site in `Help > Update... > Manage update
  sites`, install it, and restart Fiji.

### Installation

The runnable macros are inside the repository's `plugin/` directory.
Place the contents of that directory together in a Fiji macro directory:

```text
Fiji.app/plugins/MEL_quantification/
|-- run_gui.ijm
|-- nuclei/
|-- cytoplasm/
`-- membrane/
```

Then restart ImageJ. The plugin appears under the Plugins menu (MEL_quantification).